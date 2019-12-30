#!/bin/sh
sudo /bin/bash /etc/init.d/xvfb start 
SKIP_COMPATIBILITY_REGEXPS=1 /home/$USER/.rvm/bin/rvm $RUBY_VERSION do bundle exec rspec "$@"
