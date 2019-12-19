#!/bin/sh

# NOTE every which is intentionally kept without redirection output to /dev/null

brew update --verbose
brew install vim -- --with-client-server
vim --version
# brew install macvim -- --with-override-system-vim
# wget https://github.com/macvim-dev/macvim/releases/download/snapshot-161/MacVim.dmg -P /tmp
# hdiutil attach /tmp/MacVim.dmg
# sudo cp -R /Volumes/MacVim/MacVim.app /Applications
# hdiutil detach /Volumes/MacVim

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
