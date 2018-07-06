bash .ci/install_dependencies.sh
bundle install

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then bash .ci/install_osx.sh; fi
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then bash .ci/install_linux.sh; fi
"export DISPLAY=:99.0"
if [ "$TRAVIS_OS_NAME" = "linux" ]; then sh -e /etc/init.d/xvfb start; fi
if [ "$TRAVIS_OS_NAME" = "osx" ]; then ( sudo Xvfb :99 -ac -screen 0 1024x768x8; echo ok ) & fi
sleep 3 # give xvfb some time to start
