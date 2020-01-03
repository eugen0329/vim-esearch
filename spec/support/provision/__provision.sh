#!/bin/sh

[ -n "$__PROVISION_SH_SOURCE_ONCE" ] && return 0; __PROVISION_SH_SOURCE_ONCE=1

RUNNING_SCRIPT_DIRNAME="$(dirname "$0")"
if [ -f "$RUNNING_SCRIPT_DIRNAME/__provision.sh" ]; then
  provision_directory="$RUNNING_SCRIPT_DIRNAME"
elif [ -f "$PWD/__provision.sh" ]; then
  provision_directory="$(realpath "$PWD")"
else
  echo "Can't resolve directory from $RUNNING_SCRIPT_DIRNAME $PWD" && exit 1
fi

load() {
  . "$provision_directory/$1"
}

# shellcheck source=spec/support/provision/dependencies/vim.sh
load "dependencies/vim.sh"
# shellcheck source=spec/support/provision/dependencies/neovim.sh
load "dependencies/neovim.sh"
# shellcheck source=spec/support/provision/dependencies/ack.sh
load "dependencies/ack.sh"
# shellcheck source=spec/support/provision/dependencies/ag.sh
load "dependencies/ag.sh"
# shellcheck source=spec/support/provision/dependencies/pt.sh
load "dependencies/pt.sh"
# shellcheck source=spec/support/provision/dependencies/rg.sh
load "dependencies/rg.sh"
# shellcheck source=spec/support/provision/dependencies/plugins.sh
load "dependencies/plugins.sh"
# shellcheck source=spec/support/provision/dependencies/__installation_helpers.sh
load "__installation_helpers.sh"

set -eux
