load ../test_helper

setup() {
  git init --bare "$PROVISION_TEST_DIR/repo.git"

  mkdir -p "$PROVISION_TEST_DIR/local_copy/plugin"
  cd "$PROVISION_TEST_DIR/local_copy" || exit
  git init

  echo "file_content_commit_0" > dummy.vim
  git add .
  git commit -m 'commit 0'

  echo "file_content_commit_1" > dummy.vim
  git add .
  git commit -m 'commit 1'

  git remote add origin "$PROVISION_TEST_DIR/repo.git" > /dev/null
  git push --set-upstream origin master

  read -r -a commits <<< "$(git log --reverse '--pretty=format:%H' | tr "\n" ' ')"
  arbitrary_commit_number=$(( RANDOM % ${#commits[@]} ))
  INSTALLATION_PATH="$PROVISION_TEST_DIR/installation_path"
  cd - || exit

  export INSTALLATION_PATH arbitrary_commit_number commits
}

teardown() {
  rm -r "$PROVISION_TEST_DIR/repo.git" "$PROVISION_TEST_DIR/local_copy"
}

@test "install_vim_plugin without version" {
  install_vim_plugin                        \
    "$PROVISION_TEST_DIR/repo.git"          \
    "$PROVISION_TEST_DIR/installation_path"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_1"
}

@test "install_vim_plugin with version" {
  install_vim_plugin                        \
    "$PROVISION_TEST_DIR/repo.git"          \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[0]}"

  run git rev-parse master
  assert_not_equal "$output" "${commits[0]}"
  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_0"
}

@test "install_vim_plugin version update" {
  install_vim_plugin                        \
    "$PROVISION_TEST_DIR/repo.git"          \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[0]}"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_0"

  install_vim_plugin                        \
    "$PROVISION_TEST_DIR/repo.git"          \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[1]}"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_1"
}

@test "install_vim_plugin build instructions support" {
  # shellcheck disable=SC2016
  build_commands='echo "running command in `pwd`" > PWD.txt'

  install_vim_plugin                        \
    "$PROVISION_TEST_DIR/repo.git"          \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[$arbitrary_commit_number]}"  \
    "$build_commands"

  run cat "$PROVISION_TEST_DIR/installation_path/PWD.txt"
  assert_output "running command in $PROVISION_TEST_DIR/installation_path"
  # double check
  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_$arbitrary_commit_number"
}

@test "install_vim_plugin idempotence" {
  install_vim_plugin                        \
    "$PROVISION_TEST_DIR/repo.git"          \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[$arbitrary_commit_number]}"
  install_vim_plugin                        \
    "$PROVISION_TEST_DIR/repo.git"          \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[$arbitrary_commit_number]}"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_$arbitrary_commit_number"
}
