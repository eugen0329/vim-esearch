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

# shellcheck source=spec/support/provision/__vim.sh
load "__vim.sh"
# shellcheck source=spec/support/provision/__neovim.sh
load "__neovim.sh"
# shellcheck source=spec/support/provision/__ackloadsh
load "__ack.sh"
# shellcheck source=spec/support/provision/__agloadsh
load "__ag.sh"
# shellcheck source=spec/support/provision/__ptloadsh
load "__pt.sh"
# shellcheck source=spec/support/provision/__rgloadsh
load "__rg.sh"
# shellcheck source=spec/support/provision/__pluginsloadsh
load "__plugins.sh"
# shellcheck source=spec/support/provision/__libloadsh
load "__lib.sh"

set -eux
