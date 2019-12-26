FROM ubuntu:xenial

ARG GIT_BRANCH=master
ARG USER=docker
ARG UID=1000
ARG GID=1000
ARG RUBY_VERSION=2.3.8
ARG PLUGINS_DIR=/tmp/vim_plugins
ARG BIN_DIR=/tmp/bin

ENV USER=$USER
ENV PATH="/home/docker/.local/bin:$PATH"
ENV DISPLAY=":99.0"
ENV PLUGINS_DIR=$PLUGINS_DIR
ENV BIN_DIR=$BIN_DIR
ENV RUBY_VERSION=$RUBY_VERSION
ENV GUI=0

# Setup user
RUN apt-get update && apt-get -y install sudo
RUN addgroup --gid $GID $USER && \
      adduser --uid $UID --gid $GID --shell /bin/bash --disabled-password --gecos '' $USER && \
      adduser $USER sudo && \
      echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER $USER

# Setup container dependencies
#  software-properties-common: for add-apt-repository
RUN sudo apt-get -y install \
      git wget curl tar software-properties-common \
      xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps \
      build-essential python3 python3-dev python3-pip python3-venv

# Setup vim plugins
RUN git clone https://github.com/eugen0329/vim-esearch.git /tmp/vim-esearch && cd /tmp/vim-esearch/ && git checkout "$GIT_BRANCH"
RUN cd /tmp/vim-esearch && sh spec/support/bin/install_vim_dependencies.sh $PLUGINS_DIR

# Setup ruby
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s
RUN /home/$USER/.rvm/bin/rvm install $RUBY_VERSION --default
RUN /home/$USER/.rvm/bin/rvm $RUBY_VERSION do gem update --system --force
RUN /home/$USER/.rvm/bin/rvm $RUBY_VERSION do gem install bundler
RUN cd /tmp/vim-esearch && /home/$USER/.rvm/bin/rvm $RUBY_VERSION do bundle install

# Setup vim executables and search utils
ADD spec/support/bin/install_linux_dependencies.sh /tmp/vim-esearch/spec/support/bin/install_linux_dependencies.sh
RUN sh /tmp/vim-esearch/spec/support/bin/install_linux_dependencies.sh /tmp/bin

# Setup xvfb
ADD xvfb_init /etc/init.d/xvfb
RUN sudo chmod a+x /etc/init.d/xvfb
ADD xvfb_daemon_run /usr/bin/xvfb-daemon-run
RUN sudo chmod a+x /usr/bin/xvfb-daemon-run

# CMD /bin/bash
CMD sudo /bin/bash /etc/init.d/xvfb start && \
      cd /tmp/vim-esearch && \
      /home/$USER/.rvm/bin/rvm $RUBY_VERSION do bundle exec rspec --tag nvim
