load ../test_helper

setup() {
  git init --bare "$PROVISION_TEST_DIR/repo.git"

  mkdir -p "$PROVISION_TEST_DIR/local_copy/plugin"
  cd "$PROVISION_TEST_DIR/local_copy"
  git init

  echo "file_content_commit_0" > dummy.vim
  git add .
  git commit -m 'commit 0'

  echo "file_content_commit_1" > dummy.vim
  git add .
  git commit -m 'commit 1'

  git remote add origin "$PROVISION_TEST_DIR/repo.git" > /dev/null
  git push --set-upstream origin master

  commits=$(git log --reverse --pretty=format:"%H" | tr "\n" " " )
  commits=($commits)
  arbitrary_commit_number=$[$RANDOM % ${#commits[@]}]
  INSTALLATION_PATH="$PROVISION_TEST_DIR/installation_path"
  cd -
}

teardown() {
  rm -r "$PROVISION_TEST_DIR/repo.git" "$PROVISION_TEST_DIR/local_copy"
}

@test "Work without version specified" {
  install_vim_plugin                   \
    "$PROVISION_TEST_DIR/repo.git"     \
    "$PROVISION_TEST_DIR/installation_path"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_1"
}

@test "Changing version" {
  install_vim_plugin                   \
    "$PROVISION_TEST_DIR/repo.git"     \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[0]}"

  run git rev-parse master
  assert_not_equal "$output" "${commits[0]}" # fail fast

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_0"
}

@test "updating version" {
  install_vim_plugin                   \
    "$PROVISION_TEST_DIR/repo.git"     \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[0]}"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_0"

  install_vim_plugin                   \
    "$PROVISION_TEST_DIR/repo.git"     \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[1]}"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_1"
}


@test "make plugin support" {
  install_vim_plugin                   \
    "$PROVISION_TEST_DIR/repo.git"     \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[$arbitrary_commit_number]}" \
    'echo "running command in `pwd`" > PWD.txt'

  run cat "$PROVISION_TEST_DIR/installation_path/PWD.txt"
  assert_output "running command in $PROVISION_TEST_DIR/installation_path"
  # double check
  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_$arbitrary_commit_number"
}

@test "ensuring idempotence" {
  install_vim_plugin                   \
    "$PROVISION_TEST_DIR/repo.git"     \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[$arbitrary_commit_number]}"
  install_vim_plugin                   \
    "$PROVISION_TEST_DIR/repo.git"     \
    "$PROVISION_TEST_DIR/installation_path" \
    "${commits[$arbitrary_commit_number]}"

  run cat "$PROVISION_TEST_DIR/installation_path/dummy.vim"
  assert_output "file_content_commit_$arbitrary_commit_number"
}
