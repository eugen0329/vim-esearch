#!/bin/sh

Xvfb -ac $DISPLAY &
# TODO58
[ "$@" = 'sh' ] && exec sh
DANGEROUSLY_MAXIMIZE_PERFORMANCE=1 NVIM_GUI=0 GUI=1 SKIP_COMPATIBILITY_REGEXPS=1 exec bundle exec rspec "$@"
