#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

install_package_ack() {
  name='ack'
  version="$1"
  sudo="$2"
  link_path="${3:-}"
  create_link_to_default_in_local_directory="${4:-0}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_or_debian_like_linux; then
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" ack-grep
    $sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep || true
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" ack
  elif is_osx; then
    brew install ack
  else
    echo 'Unsupported platform' && return 1
  fi

  if is_true "$create_link_to_default_in_local_directory"; then
    create_symlink "$name" "$link_path"
  fi
}
