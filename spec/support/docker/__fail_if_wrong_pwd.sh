#!/bin/sh

{ [ ! -f "$PWD/autoload/esearch.vim" ] || [ ! -f "$PWD/plugin/esearch.vim" ]; } &&
  printf "Wrong \$PWD == %s\nMust be runned inside the plugin root.\nExiting.\n" "$PWD" &&
  exit 1
