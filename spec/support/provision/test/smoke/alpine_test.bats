load ../test_helper

setup() {
  local_bin_dir="$PROVISION_TEST_DIR/bin"
  plugins_dir="$PROVISION_TEST_DIR/plugins"
  mkdir -p "$local_bin_dir" "$plugins_dir"
  git init "$PROVISION_TEST_DIR"
}

teardown() {
  rm -r "$local_bin_dir" "$plugins_dir"
  rm -r "$PROVISION_TEST_DIR/.git"
}

@test "Smoke test of provision/alpine.sh" {
  set -x
  sh /provision/alpine.sh "$local_bin_dir" "$plugins_dir" >&3
  # assert_success

  run ragel --version
  assert_success

  run vim --version
  assert_output_includes "+clientserver"

  run "$local_bin_dir/nvim" --version
  assert_success

  run ack --version
  assert_success

  run ag --version
  assert_success

  run "$local_bin_dir/rg"  --version
  assert_success

  run git -C "$PROVISION_TEST_DIR" grep -h
  assert_output_includes 'usage: git grep'
  # seems, git-grep doesn't have --help or -h key under alpine os, but at least
  # this workaround works
  assert_equal "$status" 129

  assert_file_exists "$plugins_dir/vimproc.vim/plugin/vimproc.vim"
  assert_file_exists "$plugins_dir/vim-prettyprint/plugin/prettyprint.vim"
  # pt is installed on a separate docker build stage
  assert_file_missing "$local_bin_dir/pt"
}
