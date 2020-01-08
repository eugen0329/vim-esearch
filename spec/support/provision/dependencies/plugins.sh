#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh disable=SC2154
. "$provision_dir/__installation_helpers.sh"

install_vim_plugin() {
  local repo="$1"
  local dest="$2"
  local version="${3:-}"
  local build_commands="${4:-}"

  git_clone_and_checkout \
    "$repo"              \
    "$dest"              \
    "$version"

  [ -z "$build_commands" ] || ( cd "$dest" && eval "$build_commands" )
}
