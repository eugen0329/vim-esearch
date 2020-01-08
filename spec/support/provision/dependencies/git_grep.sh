#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh disable=SC2154
. "$provision_dir/__installation_helpers.sh"

install_package_git_grep() {
  local name='git'
  local version="$1"
  local sudo="${2:-}"
  local local_link_dest="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Not implemented error' && return 2
  fi

  if is_debian_or_debian_like_linux; then
    echo 'Not implemented error' && return 2
  elif is_alpine_linux; then
    echo 'Not implemented error' && return 2
  elif is_osx; then
    brew reinstall git -- --with-pcre2
  else
    echo "Unsupported platform error: $(uname -a)" && return 1
  fi

  [ -z "$local_link_dest" ] || create_global_executable_link "$name" "$local_link_dest"
}
