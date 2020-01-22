#!/bin/bash

# Mostly for convenience as .shellcheckrc is not working for some reason

shopt -s globstar extglob

all=(
  # sh, bash and bats files
  spec/support/**/*.sh
  spec/support/**/*.bash
  spec/support/**/*.bats
  # scripts without extensions
  spec/support/**/build!(*.*)
  spec/support/**/bats!(*.*)
  spec/support/**/run!(*.*)
  spec/support/**/shellcheck!(*.*)
  spec/support/**/rspec!(*.*)
  )

( IFS=$'\n'; echo -e "Running shellcheck for file(s):\n${*:-${all[*]}}")

# echo "Running shellcheck for file(s):"
# printf '%s\n' "${all[@]}"
shellcheck -e SC2039 --external-sources "${@:-${all[@]}}"
