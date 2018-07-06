sudo add-apt-repository ppa:jonathonf/vim -y
sudo apt update -y
sudo apt-get install -y vim 
sudo apt-get install -f -y vim-gtk

# install ack
sudo apt-get install -y ack-grep
sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep

# install ag
sudo apt-get install -y silversearcher-ag

# install rg
wget https://github.com/BurntSushi/ripgrep/releases/download/0.7.1/ripgrep-0.7.1-x86_64-unknown-linux-musl.tar.gz
tar xvfz ripgrep-0.7.1-x86_64-unknown-linux-musl.tar.gz
sudo mv ripgrep-0.7.1-x86_64-unknown-linux-musl/rg /usr/bin/rg

# install pt
wget https://github.com/monochromegane/the_platinum_searcher/releases/download/v2.1.5/pt_linux_amd64.tar.gz
tar xvfz pt_linux_amd64.tar.gz
sudo mv pt_linux_amd64/pt /usr/bin/pt
