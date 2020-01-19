#!/bin/sh

# shellcheck source=spec/support/provision/__provision.sh
. "$(dirname "$0")/__provision.sh"

local_bin_dir="${1:-"$provision_dir/../bin"}"

install_package_ragel \
  'latest'

install_package_vim \
  'latest'

install_prebuilt_neovim \
  "0.4.3"               \
  "$local_bin_dir"      \
  "$create_link_to_default_in_local_bin"

install_package_git_grep \
  'latest'

install_prebuilt_pt      \
  '2.2.0'                \
  "$local_bin_dir"       \
  "$create_link_to_default_in_local_bin"

install_package_ack      \
  'https://raw.githubusercontent.com/Homebrew/homebrew-core/a34d39a63d090f1c5d4ccb7be7149195dc8059df/Formula/ack.rb'

install_package_ag       \
  'latest'

install_prebuilt_rg      \
  '11.0.2'               \
  "$local_bin_dir"       \
  "$create_link_to_default_in_local_bin"

# shellcheck source=spec/support/provision/plugins.sh
sh "$provision_dir/default_plugins.sh" "${2:-"$provision_dir/../vim_plugins"}"
