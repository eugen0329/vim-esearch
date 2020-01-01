#!/bin/sh

Xvfb -ac "$DISPLAY" -screen 0 640x480x16 &

# consider to install debug deps on the fly
[ "$RUN_VNC" = '1' ] &&  ( x11vnc & )
# [ $RUN_VNC = '1' ] && apk add --no-cache xterm x11vnc && x11vnc  &

exec "$@"
