#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh
. "$provision_directory/__installation_helpers.sh"

build_command_noop=''

# TODO idempotence
install_vim_plugin() {
  local repo="$1"
  local dest="$2"
  local version="${3:-"$dont_checkout"}"
  local build_commands="${4:-"$build_command_noop"}"

  git_clone_and_checkout \
    "$repo"              \
    "$dest"              \
    "$version"

  if [ "$build_commands" != "$build_command_noop" ]; then
    ( cd "$dest" && eval "$build_commands" )
  fi
}

