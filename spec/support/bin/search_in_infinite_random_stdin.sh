#!/bin/sh

util=$1
shift
arguments=$@

cat /dev/urandom | $util $arguments
