#!/bin/sh

# Xvfb -ac $DISPLAY -listen tcp -screen 0 1280x1024x16 &
Xvfb -ac $DISPLAY -screen 0 1280x1024x16 &

# consider to install debug deps on the fly
[ $RUN_VNC = '1' ] && x11vnc  &
# [ $RUN_VNC = '1' ] && apk add --no-cache xterm x11vnc && x11vnc  &

# TODO58
NVIM_PATH=nvim DANGEROUSLY_MAXIMIZE_PERFORMANCE=1 NVIM_GUI=0 GUI=1 SKIP_COMPATIBILITY_REGEXPS=1 \
  exec "$@"
