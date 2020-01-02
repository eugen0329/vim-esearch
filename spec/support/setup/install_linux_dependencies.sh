#!/bin/sh

csv_line_contains() {
  csv_line="$1"
  field="$2"

  echo "$csv_line" | grep -E "(^|,)$field(,|$)" 1>/dev/null 2>&1
}

crossplatform_realpath() {
    [ "$1" = '/*' ] && \ echo "$1" || echo "$PWD/${1#./}"
}

is_local() {
  install=$1
  util=$2
  csv_line_contains "$install" "$util-local(:default)?" && echo 1
}
is_global() {
  install=$1
  util=$2
  csv_line_contains "$install" "$util-global(:default)?" && echo 1
}
is_default() {
  install=$1
  util=$2
  csv_line_contains "$install" "$util-(local|global):default" && echo 1
}

validate_install_options() {
  [ "$2" = '1' ] && echo "INSTALLING $1 locally"
  [ "$3" = '1' ] && echo "INSTALLING $1 globally"
  [ "$2" = '' ] && [ "$3" = '' ] && echo "IGNORING $1: No options for installation provided" && return 1
  return 0
}

log_unsupported() {
  echo "WARNING: $1 is unsupported"
}

install_vim() {
  install_local=$(is_local "$INSTALL" 'vim')
  install_global=$(is_global "$INSTALL" 'vim')
  validate_install_options 'vim' "$install_local" "$install_global" || return 0
  [ "$install_local" = '1' ] && log_unsupported 'vim-local'

  (
  set -eux
  if [ "$PACKAGE_MANAGER" = apt-get ] ; then
    $SUDO add-apt-repository ppa:jonathonf/vim -y
    $SUDO apt update -y
    $SUDO apt-get install -y "$APT_GET_INSTALL_LESS" vim-gtk
  elif [ "$PACKAGE_MANAGER" = apk ] ; then
    apk add "$APK_INSTALL_LESS" gvim
  fi
  )
}

install_ack() {
  install_local=$(is_local "$INSTALL" 'ack')
  install_global=$(is_global "$INSTALL" 'ack')
  validate_install_options 'ack' "$install_local" "$install_global" || return 0
  [ "$install_local" = '1' ] && log_unsupported 'ack-local'

  (
  set -eux
  if [ "$PACKAGE_MANAGER" = apt-get ] ; then
    $SUDO apt-get install -y "$APT_GET_INSTALL_LESS" ack-grep
    $SUDO dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
  elif [ "$PACKAGE_MANAGER" = apk ] ; then
    apk add "$APK_INSTALL_LESS" ack
  fi
  )
}

install_ag() {
  install_local=$(is_local "$INSTALL"  'ag')
  install_global=$(is_global "$INSTALL" 'ag')
  validate_install_options 'ag' "$install_local" "$install_global" || return 0
  [ "$install_local" = '1' ] && log_unsupported 'ag-local'

  (
  set -eux
  if [ "$PACKAGE_MANAGER" = apt-get ] ; then
    command -v ag || $SUDO apt-get install -y "$APT_GET_INSTALL_LESS" silversearcher-ag
  elif [ "$PACKAGE_MANAGER" = apk ] ; then
    apk add "$APK_INSTALL_LESS" the_silver_searcher
  fi
  )
}

install_rg() {
  rgversion=${1:-'11.0.2'}
  install_local=$(is_local "$INSTALL" 'rg')
  install_global=$(is_global "$INSTALL" 'rg')
  validate_install_options 'rg' "$install_local" "$install_global" || return 0
  link_local_to_default=$(is_default "$INSTALL" 'rg')

  (
    set -eux
    mkdir -pv "/tmp/rg-$rgversion"
    cd "/tmp/rg-$rgversion"
    wget -N "https://github.com/BurntSushi/ripgrep/releases/download/$rgversion/ripgrep-$rgversion-x86_64-unknown-linux-musl.tar.gz"
    tar xvfz "ripgrep-$rgversion-x86_64-unknown-linux-musl.tar.gz"
    cp "ripgrep-$rgversion-x86_64-unknown-linux-musl/rg" "$bin_directory/rg-$rgversion"

    if [ "$link_local_to_default" = '1' ]; then
      ln -s "$bin_directory/rg-$rgversion" "$bin_directory/rg"
    fi

    if [ "$install_global" = '1' ]; then
      $SUDO cp "ripgrep-$rgversion-x86_64-unknown-linux-musl/rg" "/usr/local/bin/rg"
    fi
  )
  rm -rvf "/tmp/rg-$rgversion"
}

install_pt() {
  ptversion=${1:-'2.2.0'}
  install_local=$(csv_line_contains "$INSTALL" 'pt-local(:default)?' && echo 1)
  install_global=$(is_global "$INSTALL" 'pt')
  validate_install_options 'pt' "$install_local" "$install_global" || return 0
  link_local_to_default=$(is_default "$INSTALL" 'pt')

  (
    set -eux
    mkdir -pv "/tmp/pt-$ptversion" &&
    cd "/tmp/pt-$ptversion" &&
    wget -N "https://github.com/monochromegane/the_platinum_searcher/releases/download/v$ptversion/pt_linux_amd64.tar.gz" &&
    tar xvfz pt_linux_amd64.tar.gz &&
    cp pt_linux_amd64/pt "$bin_directory/pt-$ptversion" &&

    if [ "$link_local_to_default" = '1' ]; then
      ln -s "$bin_directory/pt-$ptversion" "$bin_directory/pt"
    fi

    if [ "$install_global" = 1 ]; then
      $SUDO cp pt_linux_amd64/pt /usr/local/bin/pt
    fi
  )
  rm -rvf "/tmp/pt-$ptversion"
}

install_neovim() {
  # only default is supported at the moment
  install_local=$(csv_line_contains "$INSTALL" 'neovim-local(:default)?' && echo 1)
  install_global=$(is_global "$INSTALL" 'neovim')
  validate_install_options 'neovim' "$install_local" "$install_global" || return 0

  (
    set -eux
    cd "$bin_directory" &&
    wget -N https://github.com/neovim/neovim/releases/download/v0.4.3/nvim.appimage &&
    chmod +x "nvim.appimage" &&
    (./nvim.appimage --appimage-extract 1>/dev/null 2>&1 || true)
  )
  rm -v "$bin_directory/nvim.appimage"
  pip3 install "$PIP3_INSTALL_LESS" neovim-remote
}

bin_directory="${1:-"$(dirname "$(crossplatform_realpath "$0")")/../bin"}"; mkdir -pv "$bin_directory"

if [ "${ALLOW_SUDO:-'1'}" = '1' ] ; then
  SUDO=sudo
else
  SUDO=
fi

APT_GET_INSTALL_LESS='--no-install-recommends'
APK_INSTALL_LESS='--no-cache'
PIP3_INSTALL_LESS='--no-cache'

if command -v apt-get ; then
  PACKAGE_MANAGER=apt-get
else
  PACKAGE_MANAGER=apk
fi

# Available options are:
#   - util-local
#   - util-local:default
#   - util-global
INSTALL=${INSTALL:-'vim-global,neovim-local,ack-global,ag-global,rg-local:default,pt-local:default'}

install_vim
install_neovim
install_ack
install_ag
install_rg "$RG_VERSION"
install_pt "$PT_VERSION"

# vim --version
# "$bin_directory/squashfs-root/usr/bin/nvim" --version
# "$bin_directory/squashfs-root/usr/bin/nvim" --headless -c 'set nomore' -c "echo api_info()" -c qall
# "$bin_directory/squashfs-root/usr/bin/nvim" --headless -c 'echo [&shell, &shellcmdflag]' -c qall
# "$bin_directory/squashfs-root/usr/bin/nvim" --headless -c 'echo ["jobstart",exists("*jobstart"), "jobclose", exists("*jobclose"), "jobstop ", exists("*jobstop"), "jobwait ", exists("*jobwait")]' -c qall
# ack --version
# ag --version
# git --version
# grep --version
# pt --version
# rg --version

# # # command -v xterm && xterm -help
