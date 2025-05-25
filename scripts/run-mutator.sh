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
echo "Configuration file contents:"
cat "$CONFIG_PATH"

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
if [ -f "mutation-report.json" ]; then
  echo "Found mutation-report.json, extracting score..."
  
  # Extract mutation score using the actual JSON structure
  MUTATION_SCORE=$(python3 -c "
import json
import sys
try:
    with open('mutation-report.json', 'r') as f:
        data = json.load(f)
    
    # Get summary data from actual JSON structure
    summary = data.get('summary', {})
    applied = summary.get('applied', 0)
    killed = summary.get('killed', 0)
    
    # Calculate mutation score
    if applied > 0:
        score = (killed / applied) * 100
        print(f'{score:.1f}')
    else:
        print('0.0')
        
except Exception as e:
    print('0.0')
    print(f'Error parsing JSON: {e}', file=sys.stderr)
" 2>/dev/null || echo "0.0")
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

echo "Mutation testing completed successfully" 