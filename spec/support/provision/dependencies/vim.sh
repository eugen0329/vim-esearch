#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh
. "$provision_directory/__installation_helpers.sh"

install_package_vim() {
  local name='gvim'
  local version="$1"
  local sudo="$2"
  local local_link_dest="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Not implemented error' && return 2
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
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi

  [ -z "$local_link_dest" ] || create_symlink "$name" "$local_link_dest"
}
