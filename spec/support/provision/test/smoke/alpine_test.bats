load ../test_helper
# load /provision/__provision.sh

setup() {
  bin_directory="$PROVISION_TEST_DIR/bin"
  plugins_directory="$PROVISION_TEST_DIR/plugins"
  mkdir -p "$bin_directory" "$plugins_directory"
}

teardown() {
  rm -rf "$bin_directory" "$plugins_directory"
}

@test "Smoke test of provision/alpine.sh" {
  sh /provision/alpine.sh "$bin_directory" "$plugins_directory" >&3

  run "$bin_directory/nvim" --version
  assert_success

  assert vim --version | grep "+clientserver"

  run "$bin_directory/rg"  --version
  assert_success

  run ag --version
  assert_success

  run ack --version
  assert_success

  run git grep --help
  assert_success

  assert_file_exists "$plugins_directory/vimproc.vim/plugin/vimproc.vim"
  assert_file_exists "$plugins_directory/vim-prettyprint/plugin/prettyprint.vim"
  # # is installed on a separate docker build stage
  assert_file_missing "$bin_directory/pt"
}
