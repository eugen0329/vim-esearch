#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh disable=SC2154
. "$provision_dir/__installation_helpers.sh"

install_prebuilt_rg() {
  local version="$1"
  local dest="$2"
  local create_link_to_default="${3:-0}"
  local global_dest="${4:-}"
  local create_global_link_to_default="${5:-0}"

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
  local sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'rg'                                       \
    "$version"                                 \
    "$dest"                                    \
    "$create_link_to_default"                  \
    "$global_dest"                             \
    "$create_global_link_to_default"           \
    "$archive_file"                            \
    "$download_url"                            \
    "$binary_path_inside_unarchived_directory" \
    "$sudo"
}
