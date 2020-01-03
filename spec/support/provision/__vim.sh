#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_package_vim() {
  local name='gvim'
  local version="$1"
  local sudo="$2"
  local link_path="${3:-}"
  local create_link_to_default_in_local_directory="${4:-0}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_or_debian_like_linux; then
    $sudo add-apt-repository ppa:jonathonf/vim -y
    $sudo apt update -y
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" vim-gtk
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" gvim
  elif is_osx; then
    name='mvim'
    brew update --verbose
    brew install --build-from-source "$provision_directory/brew_formulae/macvim.rb" -- --with-override-system-vi
  else
    echo 'Unsupported platform' && return 1
  fi

  if is_true "$create_link_to_default_in_local_directory" ; then
    create_symlink "$name" "$link_path"
  fi
}
