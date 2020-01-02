#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_prebuilt_rg() {
  version="$1"
  into_local_directory="$2"
  into_global_directory="$3"
  link_to_default_in_local_directory="$4"
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
    "$into_local_directory"                    \
    "$into_global_directory"                   \
    "$link_to_default_in_local_directory"      \
    "$archive_file"                            \
    "$download_url"                            \
    "$binary_path_inside_unarchived_directory" \
    "$unarchive_command"                       \
    "$sudo"
}

