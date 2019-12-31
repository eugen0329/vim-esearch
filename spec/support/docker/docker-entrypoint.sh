#!/bin/sh

Xvfb -ac $DISPLAY &
# TODO58
[ "$@" = 'sh' ] && exec sh
# TODO58
NVIM_PATH=nvim DANGEROUSLY_MAXIMIZE_PERFORMANCE=1 NVIM_GUI=0 GUI=1 SKIP_COMPATIBILITY_REGEXPS=1 exec bundle exec rspec "$@"
