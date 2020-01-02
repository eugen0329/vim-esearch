#!/bin/sh

# shellcheck source=spec/support/provision/__provision.sh
. "$(dirname "$0")/__provision.sh"
local_directory_path="${1:-"$provision_directory/../bin"}"

install_package_vim       \
  'latest'                \
  "$dont_use_sudo"

install_package_neovim    \
  "latest"                \
  "$dont_use_sudo"        \
  "$local_directory_path" \
  "$create_link_to_default_in_local_directory"

## Doesn't work. Separate docker stage is used instead
# install_prebuilt_pt       \
#   '2.2.0'                 \
#   "$local_directory_path" \
#   "$skip_global_install"  \
#   "$create_link_to_default_in_local_directory"

install_package_ack       \
  'latest'                \
  "$use_sudo"

install_package_ag        \
  'latest'                \
  "$use_sudo"

install_prebuilt_rg       \
  '11.0.2'                \
  "$local_directory_path" \
  "$skip_global_install"  \
  "$create_link_to_default_in_local_directory"

# shellcheck source=spec/support/provision/plugins.sh
sh "$provision_directory/default_plugins.sh" "${2:-"$provision_directory/../vim_plugins"}"
