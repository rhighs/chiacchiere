#!/bin/bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$ROOT_DIR/test"

tests=(
  "$TEST_DIR/test_sync.sh"
  "$TEST_DIR/test_pull.sh"
  "$TEST_DIR/test_install.sh"
)

failures=0

for test_file in "${tests[@]}"; do
  if bash "$test_file"; then
    echo "PASS: $(basename "$test_file")"
  else
    echo "FAIL: $(basename "$test_file")"
    failures=$((failures + 1))
  fi
done

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "$failures test(s) failed"
  exit 1
fi

echo ""
echo "All tests passed"
