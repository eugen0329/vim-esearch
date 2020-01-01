#!/bin/sh

Xvfb -ac "$DISPLAY" -screen 0 1280x1024x16 &

# consider to install debug deps on the fly
[ "$RUN_VNC" = '1' ] &&  ( x11vnc & )
# [ $RUN_VNC = '1' ] && apk add --no-cache xterm x11vnc && x11vnc  &

exec "$@"
