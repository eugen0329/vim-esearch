#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_package_ag() {
  name=ag
  version="$1"
  sudo="$2"
  create_link_to="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_linux; then
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" silversearcher-ag
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" the_silver_searcher
  elif is_osx; then
    brew install the_silver_searcher
  else
    echo 'Unsupported platform' && return 1
  fi
  create_executable_symlink_if_path_given "$name" "$create_link_to"
}
