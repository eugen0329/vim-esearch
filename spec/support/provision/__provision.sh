#!/bin/sh

[ -n "$__PROVISION_SH_SOURCE_ONCE" ] && return 0; __PROVISION_SH_SOURCE_ONCE=1

. "$(dirname "$0")/__vim.sh"
. "$(dirname "$0")/__neovim.sh"
. "$(dirname "$0")/__ack.sh"
. "$(dirname "$0")/__ag.sh"
. "$(dirname "$0")/__pt.sh"
. "$(dirname "$0")/__rg.sh"
. "$(dirname "$0")/__plugins.sh"

. "$(dirname "$0")/__lib.sh"

set -eux
