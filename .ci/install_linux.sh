sudo add-apt-repository ppa:jonathonf/vim -y
sudo apt update -y
sudo apt-get install -y vim vim-gtk ack-grep silversearcher-ag
sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep

wget https://github.com/BurntSushi/ripgrep/releases/download/0.7.1/ripgrep-0.7.1-x86_64-unknown-linux-musl.tar.gz
tar xvfz ripgrep-0.7.1-x86_64-unknown-linux-musl.tar.gz
mv ripgrep-0.7.1-x86_64-unknown-linux-musl/rg /usr/bin/rg
