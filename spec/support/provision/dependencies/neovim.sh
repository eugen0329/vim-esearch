#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh disable=SC2154
. "$provision_dir/__installation_helpers.sh"

install_prebuilt_neovim() {
  local version="$1"
  local dest="$2"
  local create_link_to_default="${3:-0}"
  local global_dest="${4:-}"
  local create_global_link_to_default="${5:-0}"

  if is_linux; then
    local archive_file='nvim.appimage'
    local binary_path_inside_unarchived_directory="squashfs-root/usr/bin/nvim"
  elif is_osx; then
    local archive_file='nvim-macos.tar.gz'
    local binary_path_inside_unarchived_directory="nvim-osx64/bin/nvim"
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi
  local download_url="https://github.com/neovim/neovim/releases/download/v$version/$archive_file"
  local sudo="$skip_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'nvim'                                     \
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

install_package_neovim() {
  local name=nvim
  local version="$1"
  local sudo="${2:-}"
  local local_link_dest="${3:-}"

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

  [ -z "$local_link_dest" ] || create_global_executable_link "$name" "$local_link_dest"
}
