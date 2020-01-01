#!/bin/sh

{ [ ! -f "$PWD/autoload/esearch.vim" ] || [ ! -f "$PWD/plugin/esearch.vim" ]; } &&
  printf "Wrong \$PWD == $PWD\nMust be runned inside the plugin root.\nExiting.\n" $PWD &&
  exit 1
