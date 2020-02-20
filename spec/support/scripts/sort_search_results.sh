#!/bin/sh

"$@" | sort -t : -k 1,1 -k 2n,2n
