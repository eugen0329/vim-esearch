brew update
brew install macvim 8.1-161 --with-override-system-vim
brew install ack
brew install the_silver_searcher
brew install the_platinum_searcher

# brew hangs for too long time on boost setup (rg dependency)
# brew install ripgrep
rgversion=11.0.2
rgfolder=ripgrep-$rgversion-x86_64-apple-darwin
wget https://github.com/BurntSushi/ripgrep/releases/download/$rgversion/$rgfolder.tar.gz -P /tmp
tar xvfz /tmp/$rgfolder.tar.gz --directory /tmp
sudo mv /tmp/$rgfolder/rg /usr/local/bin/rg

brew reinstall --with-pcre git
