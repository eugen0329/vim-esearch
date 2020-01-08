#!/bin/bash

# Mostly for convenience as .shellcheckrc is not working for some reason

shopt -s globstar

all=(                                     \
  spec/support/**/*.sh                    \
  spec/support/**/*.bash                  \
  spec/support/**/*.bats                  \
  spec/support/**/build*                  \
  spec/support/**/run*                    \
  spec/support/**/bats                    \
  spec/support/docker/{shellcheck,rspec}* \
  )

echo -e "Running shellcheck for file(s): ${*:-${all[*]}}"
shellcheck -e SC2039 --external-sources "${@:-${all[@]}}"
