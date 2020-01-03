#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh
. "$provision_directory/__installation_helpers.sh"

install_prebuilt_neovim() {
  local version="$1"
  local local_directory_path="$2"
  local global_directory_path="$3"
  local create_link_to_default_in_local_directory="${4:-0}"
  if is_linux; then
    local archive_file='nvim.appimage'
    local binary_path_inside_unarchived_directory="squashfs-root/usr/bin/nvim"
    local unarchive_command="chmod +x '$archive_file'; ./'$archive_file' --appimage-extract"
  elif is_osx; then
    local archive_file='nvim-macos.tar.gz'
    local binary_path_inside_unarchived_directory="nvim-osx64/bin/nvim"
    local unarchive_command="$unarchive_tar"
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi
  local download_url="https://github.com/neovim/neovim/releases/download/v$version/$archive_file"
  local sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive        \
    'nvim'                                          \
    "$version"                                      \
    "$local_directory_path"                         \
    "$global_directory_path"                        \
    "$create_link_to_default_in_local_directory" \
    "$archive_file"                                 \
    "$download_url"                                 \
    "$binary_path_inside_unarchived_directory"      \
    "$unarchive_command"                            \
    "$sudo"
}

install_package_neovim() {
  local name=nvim
  local version="$1"
  local sudo="$2"
  local link_path="${3:-}"
  local create_link_to_default_in_local_directory="${4:-0}"

  if [ "$version" != 'latest' ]; then
    echo 'Not implemented error' && return 2
  fi

  if is_debian_or_debian_like_linux; then
    echo 'Not implemented error' && return 2
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" neovim
  elif is_osx; then
    echo 'Not implemented error' && return 2
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi

  if  [ "$create_link_to_default_in_local_directory" = '1' ]; then
    create_symlink "$name" "$link_path"
  fi
}
