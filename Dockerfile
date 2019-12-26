FROM ubuntu:xenial

ARG git_branch=master
ARG USER=docker
ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get -y install sudo

RUN addgroup --gid $GID $USER && \
      adduser --uid $UID --gid $GID --shell /bin/bash --disabled-password --gecos '' $USER && \
      adduser $USER sudo && \
      echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER $USER


# remove: fuse xvfb 
#
#  software-properties-common: for add-apt-repository
RUN sudo apt-get -y install \
      git wget curl tar software-properties-common \
      xvfb \
      build-essential python3 python3-dev python3-pip python3-venv

# xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps

RUN python3 -m pip install pip --upgrade

RUN git clone https://github.com/eugen0329/vim-esearch.git /tmp/vim-esearch && cd /tmp/vim-esearch/ && git checkout "$git_branch"
ARG plugins_dir=/tmp/vim_plugins
ARG bin_dir=/tmp/bin

# Install python
RUN cd /tmp/vim-esearch && sh spec/support/bin/install_vim_dependencies.sh $plugins_dir
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s

ARG RUBY_VERSION=2.3.8
RUN /home/docker/.rvm/bin/rvm install $RUBY_VERSION --default
RUN /home/docker/.rvm/bin/rvm $RUBY_VERSION do gem update --system --force
RUN /home/docker/.rvm/bin/rvm $RUBY_VERSION do gem install bundler


RUN cd /tmp/vim-esearch && /home/docker/.rvm/bin/rvm $RUBY_VERSION do bundle install

# RUN /home/docker/.rvm/bin/rvm use /tmp/vim-search --install
# RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm use 2.3.8 --install && gem update --system --force && gem install bundler"
# RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && rvm use 2.3.8 --install && gem update --system --force && gem install bundler"
# RUN /bin/bash -l -c ". /etc/profile.d/rvm.sh && cd /tmp/vim-esearch && rvm use 2.3.8 && bundle install"
# # RUN cd /tmp/vim-esearch && /etc/profile.d/rvm.sh 2.3.8 do bundle install

RUN sudo apt-get install -y xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps

# # /etc/init.d/xvfb start && . /etc/profile.d/rvm.sh &&  cd /tmp/vim-esearch
# # rspec  --tag nvim



RUN yes | sudo python3 -m pip uninstall pip && sudo apt install python3-pip --reinstall
ADD spec/support/bin/install_linux_dependencies.sh     /tmp/vim-esearch/spec/support/bin/install_linux_dependencies.sh
RUN sh /tmp/vim-esearch/spec/support/bin/install_linux_dependencies.sh /tmp/bin

ADD xvfb_init /etc/init.d/xvfb
RUN sudo chmod a+x /etc/init.d/xvfb
ADD xvfb_daemon_run /usr/bin/xvfb-daemon-run
RUN sudo chmod a+x /usr/bin/xvfb-daemon-run
# # CMD /bin/bash -l -c "/etc/init.d/xvfb start && . /etc/profile.d/rvm.sh &&  cd /tmp/vim-esearch && rspec --tag nvim"
# # CMD /bin/bash -l -c "/etc/init.d/xvfb start && . /etc/profile.d/rvm.sh &&  cd /tmp/vim-esearch && rspec --tag nvim"
# CMD /bin/bash -l -c "/etc/init.d/xvfb start &&  cd /tmp/vim-esearch && .  /etc/profile.d/rvm.sh && rvm use 2.3.8 && PLUGINS_DIR=$plugins_dir BIN_DIR=$bin_dir GUI=0 bundle exec rspec --tag nvim"

RUN cd /tmp/vim-esearch && /home/docker/.rvm/bin/rvm $RUBY_VERSION do bundle install

RUN sudo apt-get install -y xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps

RUN pip3 install neovim-remote

ENV DISPLAY :99

env PLUGINS_DIR=/tmp/vim_plugins
env BIN_DIR=/tmp/bin

ENV PATH="/home/docker/.local/bin:$PATH"
# ENV DISPLAY :99
# CMD /bin/bash
# CMD sudo /bin/bash /etc/init.d/xvfb start
CMD DISPLAY=":99.0" sudo /bin/bash /etc/init.d/xvfb start && \
      cd /tmp/vim-esearch && \
      GUI=0 /home/docker/.rvm/bin/rvm 2.3.8 do bundle exec rspec --tag nvim
