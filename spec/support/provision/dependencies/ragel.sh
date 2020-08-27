#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh disable=SC2154
. "$provision_dir/__installation_helpers.sh"

install_package_ragel() {
  local name='ragel'
  local version="$1"
  local sudo="${2:-}"
  local local_link_dest="${3:-}"

  if is_debian_or_debian_like_linux; then
    [ "$version" = 'latest' ] || { echo 'Not implemented error' && return 2; }
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" "$name"
  elif is_alpine_linux; then
    [ "$version" = 'latest' ] || { echo 'Not implemented error' && return 2; }

    apk add "$apk_argument_to_install_less" "$name"
  elif is_osx; then
    brew install "$name"
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi

  [ -z "$local_link_dest" ] || create_global_executable_link "$name" "$local_link_dest"
}
