#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_prebuilt_neovim() {
  version="${1:-'0.4.3'}"
  into_local_directory="$2"
  into_global_directory="$3"
  link_to_default_in_local_directory="$4"
  if is_linux; then
    archive_file='nvim.appimage'
    binary_path_inside_unarchived_directory="squashfs-root/usr/bin/nvim"
    unarchive_command="chmod +x '$archive_file'; ./'$archive_file' --appimage-extract"
  elif is_osx; then
    archive_file='nvim-macos.tar.gz'
    unarchive_command="$unarchive_tar"
  else
    echo "Unsupported platform" && return 1
  fi
  download_url="https://github.com/neovim/neovim/releases/download/v$version/$archive_file"
  sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'nvim'                                     \
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

install_package_neovim() {
  name=nvim
  version="$1"
  sudo="$2"
  create_link_to="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_linux; then
    echo 'Unsupported yet' && return 1
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" neovim
  elif is_osx; then
    echo 'Unsupported yet' && return 1
  else
    echo 'Unsupported platform' && return 1
  fi
  create_executable_symlink_if_path_given "$name" "$create_link_to"
}

