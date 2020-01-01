#!/bin/sh

([ ! -f "$PWD/autoload/esearch.vim" ] || [ ! -f "$PWD/plugin/esearch.vim" ]) &&
  echo "Wrong \$PWD == $PWD\nMust be runned inside the plugin root.\nExiting." &&
  exit 1
