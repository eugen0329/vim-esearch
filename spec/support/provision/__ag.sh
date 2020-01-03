#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
load "__lib.sh"

install_package_ag() {
  local name='ag'
  local version="$1"
  local sudo="$2"
  local link_path="${3:-}"
  local create_link_to_default_in_local_directory="${4:-0}"

  if [ "$version" != 'latest' ]; then
    echo 'Not implemented error' && return 2
  fi

  if is_debian_or_debian_like_linux; then
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" silversearcher-ag
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" the_silver_searcher
  elif is_osx; then
    brew install the_silver_searcher
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi

  if  is_true "$create_link_to_default_in_local_directory"; then
    create_symlink "$name" "$link_path"
  fi
}
