#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh disable=SC2154
. "$provision_dir/__installation_helpers.sh"

install_prebuilt_pt() {
  local version="$1"
  local dest="$2"
  local create_link_to_default="${3:-0}"
  local global_dest="${4:-}"
  local create_global_link_to_default="${5:-0}"

  if is_linux; then
    local directory_inside_archive="pt_linux_amd64"
    local archive_file="$directory_inside_archive.tar.gz"
  elif is_osx; then
    local directory_inside_archive="pt_darwin_amd64"
    local archive_file="$directory_inside_archive.zip"
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi
  local download_url="https://github.com/monochromegane/the_platinum_searcher/releases/download/v$version/$archive_file"
  local binary_path_inside_unarchived_directory="$directory_inside_archive/pt"
  local sudo="$skip_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'pt'                                       \
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
