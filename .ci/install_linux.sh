sudo add-apt-repository ppa:jonathonf/vim -y
sudo apt update -y
sudo apt-get install -y vim vim-gtk ack-grep silversearcher-ag
sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
