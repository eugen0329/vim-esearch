#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_prebuilt_neovim() {
  version="${1:-'0.4.3'}"
  local_directory_path="$2"
  global_directory_path="$3"
  is_create_link_to_default_in_local_directory="${4:-0}"
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
    "$local_directory_path"                    \
    "$global_directory_path"                   \
    "$is_create_link_to_default_in_local_directory"   \
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
  link_path="${3:-}"
  is_create_link_to_default_in_local_directory="${4:-0}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_or_debian_like_linux; then
    echo 'Unsupported yet' && return 1
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" neovim
  elif is_osx; then
    echo 'Unsupported yet' && return 1
  else
    echo 'Unsupported platform' && return 1
  fi

  if  [ "$is_create_link_to_default_in_local_directory" = '1' ]; then
    create_symlink "$name" "$link_path"
  fi
}

