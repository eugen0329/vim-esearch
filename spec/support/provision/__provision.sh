#!/bin/sh

. "$(dirname $0)/__vim.sh"
. "$(dirname $0)/__neovim.sh"
. "$(dirname $0)/__ack.sh"
. "$(dirname $0)/__ag.sh"
. "$(dirname $0)/__pt.sh"
. "$(dirname $0)/__rg.sh"

. "$(dirname $0)/__lib.sh"

provision_directory="$(dirname "$(crossplatform_realpath "$0")")"
bin_directory="${1:-"$(dirname "$(crossplatform_realpath "$0")")/../bin"}"
mkdir -p "$bin_directory"
set -eux
