#!/bin/bash

Xvfb :99 &
[ "$RUN_VNC" = '1' ] && x11vnc &

exec "$@"
