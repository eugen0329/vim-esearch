#!/bin/sh

[ -n "$__PROVISION_SH_SOURCE_ONCE" ] && return 0; __PROVISION_SH_SOURCE_ONCE=1

if [ -z "$provision_directory" ]; then
  RUNNING_SCRIPT_DIRNAME="$(dirname "$0")"
  if [ -f "$RUNNING_SCRIPT_DIRNAME/__provision.sh" ]; then
    provision_directory="$RUNNING_SCRIPT_DIRNAME"
  elif [ -f "$PWD/__provision.sh" ]; then
    provision_directory="$(realpath "$PWD")"
  else
    echo "Can't resolve provision/ directory" && exit 1
  fi
fi

# shellcheck source=spec/support/provision/dependencies/vim.sh
. "$provision_directory/dependencies/vim.sh"
# shellcheck source=spec/support/provision/dependencies/neovim.sh
. "$provision_directory/dependencies/neovim.sh"
# shellcheck source=spec/support/provision/dependencies/ack.sh
. "$provision_directory/dependencies/ack.sh"
# shellcheck source=spec/support/provision/dependencies/ag.sh
. "$provision_directory/dependencies/ag.sh"
# shellcheck source=spec/support/provision/dependencies/pt.sh
. "$provision_directory/dependencies/pt.sh"
# shellcheck source=spec/support/provision/dependencies/rg.sh
. "$provision_directory/dependencies/rg.sh"
# shellcheck source=spec/support/provision/dependencies/plugins.sh
. "$provision_directory/dependencies/plugins.sh"

# shellcheck source=spec/support/provision/__installation_helpers.sh
. "$provision_directory/__installation_helpers.sh"

set -eux
