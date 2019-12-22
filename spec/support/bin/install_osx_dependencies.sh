#!/bin/sh

# NOTE every which is intentionally kept without redirection output to /dev/null
crossplatform_realpath() {
    [ "$1" = '/*' ] && \ echo "$1" || echo "$PWD/${1#./}"
}
bin_directory="${1:-"$(dirname "$(crossplatform_realpath "$0")")"}"

brew update --verbose
brew install --build-from-source "$bin_directory/../brew_formula/macvim.rb" -- --with-override-system-vi
# brew install macvim -- --with-override-system-vim

command -v ack || brew install ack
command -v ag  || brew install the_silver_searcher

# brew hangs for too long time on boost setup (rg dependency)
# brew install ripgrep
if ! command -v rg; then
  rgversion=11.0.2
  rgfolder=ripgrep-$rgversion-x86_64-apple-darwin
  wget "https://github.com/BurntSushi/ripgrep/releases/download/$rgversion/$rgfolder.tar.gz" -P /tmp
  tar xvfz "/tmp/$rgfolder.tar.gz" --directory /tmp
  sudo mv "/tmp/$rgfolder/rg" /usr/local/bin/rg
fi

# command -v pt  || brew install the_platinum_searcher
# Speedup
if ! command -v pt; then
  ptfolder=pt_darwin_amd64
  wget "https://github.com/monochromegane/the_platinum_searcher/releases/download/v2.2.0/$ptfolder.zip" -P /tmp
  unzip "/tmp/$ptfolder.zip" -d /tmp
  sudo mv "/tmp/$ptfolder/pt" /usr/local/bin/pt
fi

brew reinstall git -- --with-pcre2

wget "https://github.com/neovim/neovim/releases/download/v0.4.3/nvim-macos.tar.gz" -P /tmp
tar xzvf "/tmp/nvim-macos.tar.gz" --directory "$bin_directory"
pip3 install neovim-remote

mvim --version

"$bin_directory/nvim-osx64/bin/nvim" --version
"$bin_directory/nvim-osx64/bin/nvim" --headless -c 'set nomore' -c "echo api_info()" -c qall
"$bin_directory/nvim-osx64/bin/nvim" --headless -c 'echo [&shell, &shellcmdflag]' -c qall
"$bin_directory/nvim-osx64/bin/nvim" --headless -c 'echo ["jobstart",exists("*jobstart"), "jobclose", exists("*jobclose"), "jobstop ", exists("*jobstop"), "jobwait ", exists("*jobwait")]' -c qall

ack --version
ag --version
git --version
grep --version
pt --version
rg --version
