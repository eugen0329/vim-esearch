FROM ubuntu:xenial

ARG git_branch=master

RUN apt-get update && apt-get -y install sudo git wget curl tar fuse xvfb
# RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
# USER docker

RUN cd /tmp && git clone https://github.com/eugen0329/vim-esearch.git && cd vim-esearch/ && git checkout "$git_branch"

RUN apt-get install -y build-essential python3 python3-dev python3-pip python3-venv &&  python3 -m pip install pip --upgrade


RUN cd /tmp/vim-esearch && sh spec/support/bin/install_vim_dependencies.sh "spec/support/vim_plugins" "spec/support/bin"
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s
RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm use 2.3.8 --install && gem update --system --force && gem install bundler"
RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && cd /tmp/vim-esearch && rvm use 2.3.8 && bundle install"
# RUN cd /tmp/vim-esearch && /etc/profile.d/rvm.sh 2.3.8 do bundle install

# RUN sudo apt-get  install -y xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps

# docker run --privileged  -v $PWD:/tmp/vim-esearch -it esearch
# /etc/init.d/xvfb start && . /etc/profile.d/rvm.sh &&  cd /tmp/vim-esearch
# rspec  --tag nvim

ADD xvfb_init /etc/init.d/xvfb
RUN chmod a+x /etc/init.d/xvfb
ADD xvfb_daemon_run /usr/bin/xvfb-daemon-run
RUN chmod a+x /usr/bin/xvfb-daemon-run

ENV DISPLAY :99

RUN sh  /tmp/vim-esearch/spec/support/bin/install_linux_dependencies.sh
# RUN pip3 install neovim-remote

# CMD /bin/bash -l -c "/etc/init.d/xvfb start && . /etc/profile.d/rvm.sh &&  cd /tmp/vim-esearch && rspec --tag nvim"
# CMD /bin/bash -l -c "/etc/init.d/xvfb start && . /etc/profile.d/rvm.sh &&  cd /tmp/vim-esearch && rspec --tag nvim"
CMD /bin/bash -l -c "/etc/init.d/xvfb start &&  cd /tmp/vim-esearch && .  /etc/profile.d/rvm.sh && rvm use 2.3.8 && GUI=0 bundle exec rspec --tag nvim"
