#!/bin/sh

# shellcheck source=spec/support/provision/__provision.sh
. "$(dirname "$0")/__provision.sh"
local_bin_dir="${1:-"$provision_dir/../bin"}"

install_package_vim    \
  'latest'             \
  "$skip_use_sudo"

install_package_neovim \
  "latest"             \
  "$skip_use_sudo"     \
  "$local_bin_dir/nvim"

## Doesn't work. Separate docker stage is used instead
# install_prebuilt_pt       \
#   '2.2.0'                 \
#   "$local_bin_dir" \
#   "$create_link_to_default_in_local_bin"

install_package_ack    \
  'latest'

install_package_ag     \
  'latest'             \

install_prebuilt_rg    \
  '11.0.2'             \
  "$local_bin_dir"     \
  "$create_link_to_default_in_local_bin"

# shellcheck source=spec/support/provision/plugins.sh
sh "$provision_dir/default_plugins.sh" "${2:-"$provision_dir/../vim_plugins"}"
