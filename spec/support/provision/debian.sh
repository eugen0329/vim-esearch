#!/bin/sh

# shellcheck source=spec/support/provision/__provision.sh
. "$(dirname "$0")/__provision.sh"
local_bin_dir="${1:-"$provision_dir/../bin"}"

install_package_ragel \
  'latest'            \
  "$use_sudo"

install_package_vim \
  'latest'          \
  "$use_sudo"

# install_prebuilt_neovim   \
#   "0.4.3"                 \
#   "$local_bin_dir" \
#   "$skip_global_install"  \
#   "$create_link_to_default_in_local_bin"

install_prebuilt_pt \
  '2.2.0'           \
  "$local_bin_dir"  \
  "$create_link_to_default_in_local_bin"

install_package_ack \
  'latest'          \
  "$use_sudo"

install_package_ag  \
  'latest'          \
  "$use_sudo"

install_prebuilt_rg \
  '11.0.2'          \
  "$local_bin_dir"  \
  "$create_link_to_default_in_local_bin"

# # shellcheck source=spec/support/provision/plugins.sh
sh "$provision_dir/default_plugins.sh" "${2:-"$provision_dir/../vim_plugins"}"
