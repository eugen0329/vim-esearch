#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname $0)/__lib.sh"

install_prebuilt_pt() {
  version="$1"
  into_local_directory="$2"
  into_global_directory="$3"
  link_to_default_in_local_directory="$4"
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
    "$into_local_directory"                    \
    "$into_global_directory"                   \
    "$link_to_default_in_local_directory"      \
    "$archive_file"                            \
    "$download_url"                            \
    "$binary_path_inside_unarchived_directory" \
    "$unarchive_command"                       \
    "$sudo"
}

