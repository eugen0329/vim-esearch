#!/bin/sh

util=$1
shift

# SC2002: Useless cat. Consider 'cmd < file | ..' or 'cmd file | ..' instead.
# Doesn't work with suggested fixes

# shellcheck disable=SC2002
cat /dev/urandom | $util "$@"
