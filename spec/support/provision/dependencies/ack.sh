#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh
. "$provision_dir/__installation_helpers.sh"

install_package_ack() {
  local name='ack'
  local version="$1"
  local sudo="${2:-}"
  local local_link_dest="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Not implemented error' && return 2
  fi

  if is_debian_or_debian_like_linux; then
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" ack-grep
    $sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep || true
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" ack
  elif is_osx; then
    brew install ack
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi

  [ -z "$local_link_dest" ] || create_global_executable_link "$name" "$local_link_dest"
}
