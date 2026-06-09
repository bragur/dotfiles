#!/usr/bin/env zsh
# tests/run.zsh — run every test_*.zsh in this directory
#
# Usage (from ~/dotfiles):
#   zsh zsh-abbr-hint/tests/run.zsh
#
# Exit code: 0 if all tests passed (or no tests found), non-zero otherwise.

emulate -LR zsh
setopt EXTENDED_GLOB NULL_GLOB

# Resolve the directory containing this script regardless of invocation path
local dir="${0:a:h}"

local -a test_files
test_files=( "$dir"/test_*.zsh(N) )

local total=${#test_files}
local failed=0

if (( total == 0 )); then
  print "No test files found in $dir — OK (0 tests)"
  exit 0
fi

print "Running $total test file(s) from $dir"
print ""

local f
for f in "${test_files[@]}"; do
  print "--- ${f:t} ---"
  zsh "$f"
  local rc=$?
  if (( rc != 0 )); then
    print "FAILED: ${f:t} (exit $rc)"
    (( failed++ ))
  else
    print "PASSED: ${f:t}"
  fi
  print ""
done

print "Results: $(( total - failed ))/$total test files passed"

if (( failed > 0 )); then
  print "$failed test file(s) FAILED"
  exit 1
fi

exit 0
