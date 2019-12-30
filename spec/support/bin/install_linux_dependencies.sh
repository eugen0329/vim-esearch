#!/bin/sh

# NOTE every which is intentionally kept without redirection output to /dev/null
crossplatform_realpath() {
    [ "$1" = '/*' ] && \ echo "$1" || echo "$PWD/${1#./}"
}
bin_directory="${1:-"$(dirname "$(crossplatform_realpath "$0")")"}"
mkdir -p "$bin_directory"

GLOBAL=0
SUDO='sudo'

APT_GET_INSTALL_LESS='--no-install-recommends'
APK_INSTALL_LESS='--no-cache'
PIP3_INSTALL_LESS='--no-cache'

if command -v apt-get ; then
  PACKAGE_MANAGER=apt-get
else
  PACKAGE_MANAGER=apk
fi

install_vim() {
  [ "$GLOBAL" = '1' ] && echo "WARNING: only global vim install is available (will be installed globally)"

  if [ "$PACKAGE_MANAGER" = apt-get ] ; then
    $sudo add-apt-repository ppa:jonathonf/vim -y
    $sudo apt update -y
    $sudo apt-get install -y "$APT_GET_INSTALL_LESS" vim-gtk
  elif [ "$PACKAGE_MANAGER" = apk ] ; then
    apk add "$APK_INSTALL_LESS" gvim
  fi
}

install_ack() {
  [ "$GLOBAL" = '1' ] && echo "WARNING: only global ack install is available (will be installed globally)"

  if [ "$PACKAGE_MANAGER" = apt-get ] ; then
    $sudo apt-get install -y "$APT_GET_INSTALL_LESS" ack-grep
    $sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
  elif [ "$PACKAGE_MANAGER" = apk ] ; then
    apk add "$APK_INSTALL_LESS" ack
  fi
}

install_ag() {
  [ "$GLOBAL" = '1' ] && echo "WARNING: only global ag install is available (will be installed globally)"

  if [ "$PACKAGE_MANAGER" = apt-get ] ; then
    command -v ag || $sudo apt-get install -y "$APT_GET_INSTALL_LESS" silversearcher-ag
  elif [ "$PACKAGE_MANAGER" = apk ] ; then
    apk add "$APK_INSTALL_LESS" the_silver_searcher	
  fi
}

install_rg() {
  rgversion=11.0.2
  ( mkdir -p "/tmp/rg-$rgversion" &&
    cd "/tmp/rg-$rgversion" &&
    wget -N "https://github.com/BurntSushi/ripgrep/releases/download/$rgversion/ripgrep-$rgversion-x86_64-unknown-linux-musl.tar.gz" &&
    tar xvfz "ripgrep-$rgversion-x86_64-unknown-linux-musl.tar.gz" &&
    cp "ripgrep-$rgversion-x86_64-unknown-linux-musl/rg" "$bin_directory/rg-$rgversion" &&
    ([ "$GLOBAL" = '1' ] && $sudo cp "ripgrep-$rgversion-x86_64-unknown-linux-musl/rg" "/usr/local/bin/rg" || true)
  )
  rm -rvf "/tmp/rg-$rgversion"
}

install_pt() {
  ptversion=2.1.5
  (
  mkdir -p "/tmp/pt-$ptversion" &&
    cd "/tmp/pt-$ptversion" &&
    wget -N "https://github.com/monochromegane/the_platinum_searcher/releases/download/v$ptversion/pt_linux_amd64.tar.gz" &&
    tar xvfz pt_linux_amd64.tar.gz &&
    cp pt_linux_amd64/pt "$bin_directory/pt-$ptversion" &&
    ([ "$GLOBAL" = 1 ] && $sudo cp pt_linux_amd64/pt /usr/local/bin/pt || true)
  )
  rm -rvf "/tmp/pt-$ptversion"
}

install_neovim() {
  (
  cd "$bin_directory" &&
    wget -N https://github.com/neovim/neovim/releases/download/v0.4.3/nvim.appimage &&
    chmod +x "nvim.appimage" &&
    (./nvim.appimage --appimage-extract || true)
  )
  rm $bin_directory/nvim.appimage
  pip3 install "$PIP3_INSTALL_LESS" neovim-remote
}

install_vim
install_neovim
install_ack
install_ag
install_rg
install_pt

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
