#!/bin/sh

[ -n "$__PROVISION_SH_SOURCE_ONCE" ] && return 0; __PROVISION_SH_SOURCE_ONCE=1

# shellcheck source=spec/support/provision/__vim.sh
. "$(dirname "$0")/__vim.sh"
# shellcheck source=spec/support/provision/__neovim.sh
. "$(dirname "$0")/__neovim.sh"
# shellcheck source=spec/support/provision/__ack.sh
. "$(dirname "$0")/__ack.sh"
# shellcheck source=spec/support/provision/__ag.sh
. "$(dirname "$0")/__ag.sh"
# shellcheck source=spec/support/provision/__pt.sh
. "$(dirname "$0")/__pt.sh"
# shellcheck source=spec/support/provision/__rg.sh
. "$(dirname "$0")/__rg.sh"
# shellcheck source=spec/support/provision/__plugins.sh
. "$(dirname "$0")/__plugins.sh"
# shellcheck source=spec/support/provision/__lib.sh
. "$(dirname "$0")/__lib.sh"

set -eux
