#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_package_vim() {
  name='vim'
  version="$1"
  sudo="$2"
  link_path="${3:-}"
  create_link_to_default_in_local_directory="${4:-0}"

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
    brew update --verbose
    brew install --build-from-source "$provision_directory/brew_formulae/macvim.rb" -- --with-override-system-vi
  else
    echo 'Unsupported platform' && return 1
  fi

  if  [ "$create_link_to_default_in_local_directory" = '1' ]; then
    create_symlink "$name" "$link_path"
  fi
}
