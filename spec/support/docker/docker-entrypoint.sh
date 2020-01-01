#!/bin/sh

Xvfb -ac $DISPLAY -listen tcp -screen 0 1280x1024x16 &

# TODO58
NVIM_PATH=nvim DANGEROUSLY_MAXIMIZE_PERFORMANCE=1 NVIM_GUI=0 GUI=1 SKIP_COMPATIBILITY_REGEXPS=1 \
  exec "$@"
