#!/bin/bash
set -e

echo "Running tree-mutator..."

# Check if config file exists in the workspace
if [ ! -f "$CONFIG_PATH" ]; then
  echo "Error: Configuration file '$CONFIG_PATH' not found in workspace"
  echo "Please ensure the obrasa.yaml file exists at the specified path"
  exit 1
fi

echo "Using configuration file: $CONFIG_PATH"

# Run the mutation testing with the new --config option
echo "Starting mutation testing..."

# Determine which binary to use (handle renamed binary to avoid directory conflicts)
if [ -f "./mutator-bin" ]; then
  MUTATOR_BINARY="./mutator-bin"
elif [ -f "./mutator" ]; then
  MUTATOR_BINARY="./mutator"
else
  echo "❌ Error: No mutator binary found (looked for ./mutator and ./mutator-bin)"
  exit 1
fi

echo "Using binary: $MUTATOR_BINARY"
$MUTATOR_BINARY test --config "$CONFIG_PATH"

# Extract mutation score from the JSON report
MUTATION_SCORE="0.0"
APPLIED=0
KILLED=0
SURVIVED=0
TIMEOUT=0
ERROR=0

if [ -f "mutation-report.json" ]; then
  echo "Found mutation-report.json, extracting score..."
  
  # Extract mutation score and detailed metrics using the actual JSON structure
  METRICS=$(python3 -c "
import json
import sys
try:
    with open('mutation-report.json', 'r') as f:
        data = json.load(f)
    
    # Get summary data from actual JSON structure
    summary = data.get('summary', {})
    applied = summary.get('applied', 0)
    killed = summary.get('killed', 0)
    survived = summary.get('survived', 0)
    timeout = summary.get('timeout', 0)
    error = summary.get('error', 0)
    
    # Calculate mutation score
    if applied > 0:
        score = (killed / applied) * 100
        print(f'{score:.1f}|{applied}|{killed}|{survived}|{timeout}|{error}')
    else:
        print('0.0|0|0|0|0|0')
        
except Exception as e:
    print('0.0|0|0|0|0|0')
    print(f'Error parsing JSON: {e}', file=sys.stderr)
" 2>/dev/null || echo "0.0|0|0|0|0|0")

  # Parse the metrics
  IFS='|' read -r MUTATION_SCORE APPLIED KILLED SURVIVED TIMEOUT ERROR <<< "$METRICS"
else
  echo "No mutation-report.json found"
  MUTATION_SCORE="0.0"
fi

# Ensure we have a numeric value
if ! [[ "$MUTATION_SCORE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Warning: Could not extract valid mutation score, defaulting to 0.0"
  MUTATION_SCORE="0.0"
fi

echo "Mutation testing completed"
echo "Mutation score: $MUTATION_SCORE%"

# Set outputs for all report formats
echo "mutation-score=$MUTATION_SCORE" >> $GITHUB_OUTPUT

# Set report paths if they exist
if [ -f "mutation-report.json" ]; then
  echo "report-json=mutation-report.json" >> $GITHUB_OUTPUT
fi

if [ -f "mutation-report.html" ]; then
  echo "report-html=mutation-report.html" >> $GITHUB_OUTPUT
fi

if [ -f "mutation-report.md" ]; then
  echo "report-markdown=mutation-report.md" >> $GITHUB_OUTPUT
fi

# Check target score if provided
TARGET_MET="true"
if [ -n "$TARGET_SCORE" ] && [ "$TARGET_SCORE" != "" ]; then
  echo "Target mutation score: $TARGET_SCORE%"
  
  # Compare scores using bc for floating point comparison
  if command -v bc >/dev/null 2>&1; then
    if (( $(echo "$MUTATION_SCORE < $TARGET_SCORE" | bc -l) )); then
      TARGET_MET="false"
      echo "❌ Mutation score ($MUTATION_SCORE%) is below target ($TARGET_SCORE%)"
      echo "target-met=false" >> $GITHUB_OUTPUT
      exit 1
    else
      echo "✅ Mutation score ($MUTATION_SCORE%) meets target ($TARGET_SCORE%)"
      echo "target-met=true" >> $GITHUB_OUTPUT
    fi
  else
    # Fallback to integer comparison if bc is not available
    MUTATION_SCORE_INT=${MUTATION_SCORE%.*}
    TARGET_SCORE_INT=${TARGET_SCORE%.*}
    if [ "$MUTATION_SCORE_INT" -lt "$TARGET_SCORE_INT" ]; then
      TARGET_MET="false"
      echo "❌ Mutation score ($MUTATION_SCORE%) is below target ($TARGET_SCORE%)"
      echo "target-met=false" >> $GITHUB_OUTPUT
      exit 1
    else
      echo "✅ Mutation score ($MUTATION_SCORE%) meets target ($TARGET_SCORE%)"
      echo "target-met=true" >> $GITHUB_OUTPUT
    fi
  fi
else
  echo "No target score specified, skipping threshold check"
  echo "target-met=true" >> $GITHUB_OUTPUT
fi

# Create a zip archive of all mutation reports
echo "📦 Creating mutation reports archive..."
REPORTS_ARCHIVE="mutation-reports.zip"

# Check which reports exist and add them to the archive
REPORT_FILES=()
if [ -f "mutation-report.json" ]; then
  REPORT_FILES+=("mutation-report.json")
fi
if [ -f "mutation-report.html" ]; then
  REPORT_FILES+=("mutation-report.html")
fi
if [ -f "mutation-report.md" ]; then
  REPORT_FILES+=("mutation-report.md")
fi

# Create zip archive if we have reports
if [ ${#REPORT_FILES[@]} -gt 0 ]; then
  zip -q "$REPORTS_ARCHIVE" "${REPORT_FILES[@]}"
  echo "✅ Created reports archive: $REPORTS_ARCHIVE"
  echo "📋 Archive contents:"
  unzip -l "$REPORTS_ARCHIVE"
  
  # Set archive path as output
  echo "reports-archive=$REPORTS_ARCHIVE" >> $GITHUB_OUTPUT
else
  echo "⚠️  No mutation reports found to archive"
fi

# Create GitHub Actions summary table
echo "📊 Creating workflow summary..."

# Determine if we're in a matrix build and create appropriate title
MATRIX_INFO=""
if [ -n "$GITHUB_JOB" ]; then
  # Try to detect matrix variables from common environment variables
  MATRIX_VARS=""
  
  # Check for common matrix variables
  if [ -n "$MATRIX_OS" ]; then
    MATRIX_VARS="${MATRIX_VARS}OS: $MATRIX_OS "
  fi
  
  # Add any other matrix variables from environment
  for var in $(env | grep '^MATRIX_' | cut -d= -f1); do
    if [[ ! "$var" =~ ^MATRIX_OS$ ]]; then
      value=$(eval echo \$$var)
      clean_var=$(echo "$var" | sed 's/MATRIX_//' | tr '[:upper:]' '[:lower:]')
      MATRIX_VARS="${MATRIX_VARS}${clean_var}: $value "
    fi
  done
  
  if [ -n "$MATRIX_VARS" ]; then
    MATRIX_INFO=" ($MATRIX_VARS)"
  fi
fi

cat >> $GITHUB_STEP_SUMMARY << EOF
# 🧬 Mutation Testing Results${MATRIX_INFO}

## Summary
| Metric | Value |
|--------|-------|
| **Mutation Score** | **${MUTATION_SCORE}%** |
| **Applied Mutations** | ${APPLIED:-0} |
| **Killed Mutations** | ${KILLED:-0} |
| **Survived Mutations** | ${SURVIVED:-0} |
| **Timeout Mutations** | ${TIMEOUT:-0} |
| **Error Mutations** | ${ERROR:-0} |

## Status
EOF

# Add target score status if specified
if [ -n "$TARGET_SCORE" ] && [ "$TARGET_SCORE" != "" ]; then
  if [ "$TARGET_MET" = "true" ]; then
    cat >> $GITHUB_STEP_SUMMARY << EOF
✅ **Target Met**: Mutation score (${MUTATION_SCORE}%) meets target (${TARGET_SCORE}%)
EOF
  else
    cat >> $GITHUB_STEP_SUMMARY << EOF
❌ **Target Not Met**: Mutation score (${MUTATION_SCORE}%) below target (${TARGET_SCORE}%)
EOF
  fi
else
  cat >> $GITHUB_STEP_SUMMARY << EOF
ℹ️ **No Target Set**: Mutation testing completed without score threshold
EOF
fi

# Add reports section
cat >> $GITHUB_STEP_SUMMARY << EOF

## Generated Reports
EOF

if [ -f "mutation-report.json" ]; then
  cat >> $GITHUB_STEP_SUMMARY << EOF
- 📄 JSON Report: \`mutation-report.json\`
EOF
fi

if [ -f "mutation-report.html" ]; then
  cat >> $GITHUB_STEP_SUMMARY << EOF
- 🌐 HTML Report: \`mutation-report.html\`
EOF
fi

if [ -f "mutation-report.md" ]; then
  cat >> $GITHUB_STEP_SUMMARY << EOF
- 📝 Markdown Report: \`mutation-report.md\`
EOF
fi

if [ -f "$REPORTS_ARCHIVE" ]; then
  cat >> $GITHUB_STEP_SUMMARY << EOF
- 📦 Reports Archive: \`$REPORTS_ARCHIVE\`
EOF
fi

cat >> $GITHUB_STEP_SUMMARY << EOF

---
*Mutation testing completed with Obrasa Tree Mutator*
EOF

# Add matrix build note if applicable
if [ -n "$MATRIX_INFO" ]; then
  cat >> $GITHUB_STEP_SUMMARY << EOF

> **Note**: This is one job in a matrix build. Each matrix combination will have its own summary.
EOF
fi

echo "Mutation testing completed successfully" 