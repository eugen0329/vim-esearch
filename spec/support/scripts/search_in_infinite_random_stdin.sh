#!/bin/sh

util=$1
shift
cat /dev/urandom | $util "$@"
