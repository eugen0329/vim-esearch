#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh
load "__installation_helpers.sh"

install_prebuilt_rg() {
  local version="$1"
  local local_directory_path="$2"
  local global_directory_path="$3"
  local create_link_to_default_in_local_directory="${4:-0}"
  if is_linux; then
    local directory_inside_archive="ripgrep-$version-x86_64-unknown-linux-musl"
  elif is_osx; then
    local directory_inside_archive="ripgrep-$version-x86_64-apple-darwin"
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi
  local archive_file="$directory_inside_archive.tar.gz"
  local download_url="https://github.com/BurntSushi/ripgrep/releases/download/$version/$archive_file"
  local binary_path_inside_unarchived_directory="$directory_inside_archive/rg"
  local unarchive_command="$unarchive_tar"
  local sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive     \
    'rg'                                         \
    "$version"                                   \
    "$local_directory_path"                      \
    "$global_directory_path"                     \
    "$create_link_to_default_in_local_directory" \
    "$archive_file"                              \
    "$download_url"                              \
    "$binary_path_inside_unarchived_directory"   \
    "$unarchive_command"                         \
    "$sudo"
}

