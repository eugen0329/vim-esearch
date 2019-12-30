#!/bin/sh

Xvfb -ac :99 -listen tcp &
NVIM_GUI=0 GUI=1 SKIP_COMPATIBILITY_REGEXPS=1 exec bundle exec rspec "$@"
