#!/bin/sh

# NOTE every which is intentionally kept without redirection output to /dev/null

# brew update
brew install macvim -- --with-override-system-vim

which ack || brew install ack
which ag  || brew install the_silver_searcher
which pt  || brew install the_platinum_searcher

# brew hangs for too long time on boost setup (rg dependency)
# brew install ripgrep
if ! which rg; then
  rgversion=11.0.2
  rgfolder=ripgrep-$rgversion-x86_64-apple-darwin
  wget https://github.com/BurntSushi/ripgrep/releases/download/$rgversion/$rgfolder.tar.gz -P /tmp
  tar xvfz /tmp/$rgfolder.tar.gz --directory /tmp
  sudo mv /tmp/$rgfolder/rg /usr/local/bin/rg
fi

brew reinstall git -- --with-pcre2
