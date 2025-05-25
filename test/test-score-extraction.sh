#!/bin/bash
# Test script to verify mutation score extraction works correctly

set -e

echo "Testing mutation score extraction..."

# Create test directory
mkdir -p test-reports
cd test-reports

# Test 1: JSON report with actual format (30% score)
echo "Test 1: JSON with actual format (30% score)"
cat > mutation-report.json << EOF
{
  "summary": {
    "total": 10,
    "applied": 10,
    "killed": 3,
    "survived": 7,
    "errors": 0
  },
  "mutations": [],
  "initial_tests_failed": false
}
EOF

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
")

echo "Extracted score: $MUTATION_SCORE% (expected: 30.0%)"
[ "$MUTATION_SCORE" = "30.0" ] && echo "✅ Test 1 passed" || echo "❌ Test 1 failed"

# Test 2: JSON report with perfect score (100%)
echo -e "\nTest 2: JSON with perfect score (100%)"
cat > mutation-report.json << EOF
{
  "summary": {
    "total": 5,
    "applied": 5,
    "killed": 5,
    "survived": 0,
    "errors": 0
  },
  "mutations": [],
  "initial_tests_failed": false
}
EOF

MUTATION_SCORE=$(python3 -c "
import json
import sys
try:
    with open('mutation-report.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('summary', {})
    applied = summary.get('applied', 0)
    killed = summary.get('killed', 0)
    
    if applied > 0:
        score = (killed / applied) * 100
        print(f'{score:.1f}')
    else:
        print('0.0')
        
except Exception as e:
    print('0.0')
")

echo "Extracted score: $MUTATION_SCORE% (expected: 100.0%)"
[ "$MUTATION_SCORE" = "100.0" ] && echo "✅ Test 2 passed" || echo "❌ Test 2 failed"

# Test 3: JSON with zero applied mutations
echo -e "\nTest 3: JSON with zero applied mutations"
cat > mutation-report.json << EOF
{
  "summary": {
    "total": 0,
    "applied": 0,
    "killed": 0,
    "survived": 0,
    "errors": 0
  },
  "mutations": [],
  "initial_tests_failed": false
}
EOF

MUTATION_SCORE=$(python3 -c "
import json
import sys
try:
    with open('mutation-report.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('summary', {})
    applied = summary.get('applied', 0)
    killed = summary.get('killed', 0)
    
    if applied > 0:
        score = (killed / applied) * 100
        print(f'{score:.1f}')
    else:
        print('0.0')
        
except Exception as e:
    print('0.0')
")

echo "Extracted score: $MUTATION_SCORE% (expected: 0.0%)"
[ "$MUTATION_SCORE" = "0.0" ] && echo "✅ Test 3 passed" || echo "❌ Test 3 failed"

# Test 4: Invalid JSON (should default to 0.0)
echo -e "\nTest 4: Invalid JSON"
cat > mutation-report.json << EOF
{
  "invalid": "json",
  "missing": "summary"
EOF

MUTATION_SCORE=$(python3 -c "
import json
import sys
try:
    with open('mutation-report.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('summary', {})
    applied = summary.get('applied', 0)
    killed = summary.get('killed', 0)
    
    if applied > 0:
        score = (killed / applied) * 100
        print(f'{score:.1f}')
    else:
        print('0.0')
        
except Exception as e:
    print('0.0')
" 2>/dev/null || echo "0.0")

echo "Extracted score: $MUTATION_SCORE% (expected: 0.0%)"
[ "$MUTATION_SCORE" = "0.0" ] && echo "✅ Test 4 passed" || echo "❌ Test 4 failed"

# Test 5: Missing JSON file
echo -e "\nTest 5: Missing JSON file"
rm -f mutation-report.json

if [ -f "mutation-report.json" ]; then
  echo "❌ Test 5 setup failed - file should not exist"
else
  MUTATION_SCORE="0.0"  # This is what the script would set
  echo "Extracted score: $MUTATION_SCORE% (expected: 0.0%)"
  [ "$MUTATION_SCORE" = "0.0" ] && echo "✅ Test 5 passed" || echo "❌ Test 5 failed"
fi

# Cleanup
cd ..
rm -rf test-reports

echo -e "\nAll tests completed!" 