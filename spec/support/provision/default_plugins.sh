#!/bin/sh

# shellcheck source=spec/support/provision/__provision.sh
. "$(dirname "$0")/__provision.sh"

plugins_dir="${1:-"$provision_dir/../vim_plugins"}"

install_vim_plugin                            \
  'https://github.com/Shougo/vimproc.vim'     \
  "$plugins_dir/vimproc.vim"                  \
  '89065f62883edb10a99aa1b1640d6d411907316b'  \
  "make"

install_vim_plugin                                          \
  'https://github.com/altercation/vim-colors-solarized.git' \
  "$plugins_dir/vim-colors-solarized"                       \
  '528a59f26d12278698bb946f8fb82a63711eec21'
