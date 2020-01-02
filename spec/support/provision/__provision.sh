#!/bin/sh

. "$(dirname "$0")/__vim.sh"
. "$(dirname "$0")/__neovim.sh"
. "$(dirname "$0")/__ack.sh"
. "$(dirname "$0")/__ag.sh"
. "$(dirname "$0")/__pt.sh"
. "$(dirname "$0")/__rg.sh"

. "$(dirname "$0")/__lib.sh"

mkdir -p "$bin_directory"
set -eux
