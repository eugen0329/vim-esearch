#!/bin/sh

# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

build_command_noop=''

# TODO idempotence
install_vim_plugin() {
  repository_url="$1"
  clone_path="$2"
  branch="${3:-"$pull_all_branches"}"
  commit_hash="${4:-"$dont_checkout"}"
  build_commands="${5:-"$build_command_noop"}"

  git_clone_and_checkout \
    "$repository_url"    \
    "$clone_path"        \
    "$branch"            \
    "$commit_hash"

  if [ "$build_commands" != "$build_command_noop" ]; then
    ( cd "$clone_path" && eval "$build_commands" )
  fi
}

