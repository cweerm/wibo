#!/usr/bin/env bash
# Runs every test_*.exe in a fixture directory and reports each result.
#
# Usage: .github/run-fixtures.sh <fixture-dir> [runner...]   (runner: wine, or none on Windows)
#
# Fixtures run from test/, the working directory ctest gives them under wibo.
set -uo pipefail

bin="$(cd "$1" && pwd)"
shift
cd "$(dirname "${BASH_SOURCE[0]}")/../test"

passed=()
failed=()
for exe in "$bin"/test_*.exe; do
  name="$(basename "$exe" .exe)"
  output="$(timeout 120 "$@" "$exe" 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    passed+=("$name")
    echo "PASS $name"
  else
    failed+=("$name")
    echo "FAIL $name (exit $status)"
    printf '%s\n' "$output" | sed 's/^/    /'
  fi
done

echo "${#passed[@]} passed, ${#failed[@]} failed"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "${#passed[@]} passed, ${#failed[@]} failed"
    for name in "${failed[@]}"; do echo "- FAIL \`$name\`"; done
  } >> "$GITHUB_STEP_SUMMARY"
fi
[ "${#failed[@]}" -eq 0 ]
