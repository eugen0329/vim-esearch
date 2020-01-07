#!/bin/sh

# shellcheck source=spec/support/provision/__provision.sh
. "$(dirname "$0")/__provision.sh"

plugins_directory="${1:-"$provision_directory/../vim_plugins"}"

install_vim_plugin                            \
  'https://github.com/Shougo/vimproc.vim'     \
  "$plugins_directory/vimproc.vim"            \
  '89065f62883edb10a99aa1b1640d6d411907316b'  \
  "make"

install_vim_plugin                            \
  'https://github.com/thinca/vim-prettyprint' \
  "$plugins_directory/vim-prettyprint"        \
  'd6060d2b1ff1cff71714e126addd3b10883ade12'
