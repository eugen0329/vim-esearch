#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
load "__lib.sh"

install_prebuilt_pt() {
  local version="$1"
  local local_directory_path="$2"
  local global_directory_path="$3"
  local create_link_to_default_in_local_directory="${4:-0}"
  if is_linux; then
    local directory_inside_archive="pt_linux_amd64"
    local archive_file="$directory_inside_archive.tar.gz"
    local unarchive_command="$unarchive_tar"
  elif is_osx; then
    local directory_inside_archive="pt_darwin_amd64"
    local archive_file="$directory_inside_archive.zip"
    local unarchive_command="$unarchive_zip"
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi
  local download_url="https://github.com/monochromegane/the_platinum_searcher/releases/download/v$version/$archive_file"
  local binary_path_inside_unarchived_directory="$directory_inside_archive/pt"
  local sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive     \
    'pt'                                         \
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

