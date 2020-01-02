#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_prebuilt_rg() {
  version="$1"
  local_directory_path="$2"
  global_directory_path="$3"
  is_create_link_to_default_in_local_directory="${4:-0}"
  if is_linux; then
    directory_inside_archive="ripgrep-$version-x86_64-unknown-linux-musl"
  elif is_osx; then
    directory_inside_archive="ripgrep-$version-x86_64-apple-darwin"
  else
    echo "Unsupported platform" && return 1
  fi
  archive_file="$directory_inside_archive.tar.gz"
  download_url="https://github.com/BurntSushi/ripgrep/releases/download/$version/$archive_file"
  binary_path_inside_unarchived_directory="$directory_inside_archive/rg"
  unarchive_command="$unarchive_tar"
  sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'rg'                                       \
    "$version"                                 \
    "$local_directory_path"                    \
    "$global_directory_path"                   \
    "$is_create_link_to_default_in_local_directory"   \
    "$archive_file"                            \
    "$download_url"                            \
    "$binary_path_inside_unarchived_directory" \
    "$unarchive_command"                       \
    "$sudo"
}

