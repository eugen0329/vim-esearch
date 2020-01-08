#!/bin/sh

[ -n "$__PROVISION_SH_SOURCE_ONCE" ] && return 0; __PROVISION_SH_SOURCE_ONCE=1

if [ -z "$provision_dir" ]; then
  if [ -f "$(dirname "$0")/__provision.sh" ]; then
    provision_dir="$(dirname "$0")"
  elif [ -f "$PWD/__provision.sh" ]; then
    provision_dir="$(realpath "$PWD")"
  else
    echo "Can't resolve \$provision_dir, try to specify it directly" && exit 1
  fi
fi

# shellcheck source=spec/support/provision/dependencies/vim.sh
. "$provision_dir/dependencies/vim.sh"
# shellcheck source=spec/support/provision/dependencies/neovim.sh
. "$provision_dir/dependencies/neovim.sh"
# shellcheck source=spec/support/provision/dependencies/ack.sh
. "$provision_dir/dependencies/ack.sh"
# shellcheck source=spec/support/provision/dependencies/ag.sh
. "$provision_dir/dependencies/ag.sh"
# shellcheck source=spec/support/provision/dependencies/pt.sh
. "$provision_dir/dependencies/pt.sh"
# shellcheck source=spec/support/provision/dependencies/rg.sh
. "$provision_dir/dependencies/rg.sh"
# shellcheck source=spec/support/provision/dependencies/plugins.sh
. "$provision_dir/dependencies/plugins.sh"

# shellcheck source=spec/support/provision/__installation_helpers.sh
. "$provision_dir/__installation_helpers.sh"

set -eu
[ "${verbose:-1}" = '0' ] || set -x
