#!/bin/sh

Xvfb -ac "$DISPLAY" -screen 0 640x480x16 &

[ "$RUN_VNC" = '1' ] && x11vnc &

exec "$@"
