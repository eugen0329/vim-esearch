#!/bin/sh

# shellcheck source=spec/support/provision/__installation_helpers.sh
load "__installation_helpers.sh"

build_command_noop=''

# TODO idempotence
install_vim_plugin() {
  local repository_url="$1"
  local clone_path="$2"
  local branch="${3:-"$pull_all_branches"}"
  local commit_hash="${4:-"$dont_checkout"}"
  local build_commands="${5:-"$build_command_noop"}"

  git_clone_and_checkout \
    "$repository_url"    \
    "$clone_path"        \
    "$branch"            \
    "$commit_hash"

  if [ "$build_commands" != "$build_command_noop" ]; then
    ( cd "$clone_path" && eval "$build_commands" )
  fi
}

