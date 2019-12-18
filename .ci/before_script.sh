bash .ci/install_vim_dependencies.sh
bundle install

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then bash .ci/install_osx.sh; fi
if [ "$TRAVIS_OS_NAME" = "osx" ]; then (( sudo Xvfb :99 -ac -screen 0 1024x768x8; echo ok) &); sleep 5; fi
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then bash .ci/install_linux.sh; fi
# if [ "$TRAVIS_OS_NAME" = "linux" ]; then DISPLAY=":99.0" sh -e /etc/init.d/xvfb start; sleep 5 fi 


if [ "$TRAVIS_OS_NAME" = "osx" ]; then
  mvim --version
else
  vim --version
fi
ack --version
ag --version
git --version
grep --version
pt --version
rg --version
