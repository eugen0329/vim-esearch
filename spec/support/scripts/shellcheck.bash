#!/bin/bash

# Required for travis as globbing isn't working in .travis.yml and .shellcheckrc
# is not working

# --external-sources: Allow 'source' outside of FILES
exec shellcheck -e SC2039 --external-sources \
    spec/support/**/*.sh                     \
    spec/support/**/*.bash                   \
    spec/support/**/*.bats                   \
    spec/support/**/build*                   \
    spec/support/**/run*                     \
    spec/support/docker/rspec*               \
    spec/support/provision/test/bats
