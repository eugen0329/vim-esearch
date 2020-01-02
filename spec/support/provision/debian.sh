#!/bin/sh

# shellcheck source=spec/support/provision/__provision.sh
. "$(dirname "$0")/__provision.sh"

into_local_directory="$bin_directory"

install_package_vim       \
  'latest'                \
  "$using_sudo"

install_prebuilt_neovim   \
  "0.4.3"                 \
  "$into_local_directory" \
  "$skip_global_install"  \
  "$link_to_default_in_local_directory"

install_prebuilt_pt       \
  '2.2.0'                 \
  "$into_local_directory" \
  "$skip_global_install"  \
  "$link_to_default_in_local_directory"

install_package_ack       \
  'latest'                \
  "$using_sudo"

install_package_ag        \
  'latest'                \
  "$using_sudo"

install_prebuilt_rg       \
  '11.0.2'                \
  "$into_local_directory" \
  "$skip_global_install"  \
  "$link_to_default_in_local_directory"
