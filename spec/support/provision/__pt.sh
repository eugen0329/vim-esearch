#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_prebuilt_pt() {
  version="$1"
  local_directory_path="$2"
  global_directory_path="$3"
  is_create_link_to_default_in_local_directory="${4:-0}"
  if is_linux; then
    directory_inside_archive="pt_linux_amd64"
    archive_file="$directory_inside_archive.tar.gz"
    unarchive_command="$unarchive_tar"
  elif is_osx; then
    directory_inside_archive="pt_darwin_amd64"
    archive_file="$directory_inside_archive.zip"
    unarchive_command="$unarchive_zip"
  else
    echo "Unsupported platform" && return 1
  fi
  download_url="https://github.com/monochromegane/the_platinum_searcher/releases/download/v$version/$archive_file"
  binary_path_inside_unarchived_directory="$directory_inside_archive/pt"
  sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'pt'                                       \
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

