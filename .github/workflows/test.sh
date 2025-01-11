#!/usr/bin/env bash
set -eo pipefail

if [ "$GITHUB_MATRIX_NODE" -eq 2 ]; then
  testsToRun=hypergraphMatching
elif [ "$GITHUB_MATRIX_NODE" -eq 3 ]; then
  testsToRun=WolframModel
else
  # For nodes 0 and 1, split the remaining tests
  if [ "$GITHUB_MATRIX_NODE" -eq 0 ]; then
    # First half of the test files (excluding specific tests)
    testsToRun=($(ls Tests/*.wlt | \
      grep -v "Tests/performance.wlt" | \
      grep -v "Tests/hypergraphMatching.wlt" | \
      grep -v "Tests/WolframModel.wlt" | \
      head -n $(( $(ls Tests/*.wlt | wc -l) / 2 )) | \
      sed "s/\.wlt//" | \
      sed "s/Tests\///"))
  else
    # Second half of the test files
    testsToRun=($(ls Tests/*.wlt | \
      grep -v "Tests/performance.wlt" | \
      grep -v "Tests/hypergraphMatching.wlt" | \
      grep -v "Tests/WolframModel.wlt" | \
      tail -n +$(( $(ls Tests/*.wlt | wc -l) / 2 + 1 )) | \
      sed "s/\.wlt//" | \
      sed "s/Tests\///"))
  fi
fi

rm -f exit_status.txt
STATUS_FILE=1 ./test.wls -lip "${testsToRun[@]}"
[[ -f exit_status.txt && $(<exit_status.txt) == "0" ]] 