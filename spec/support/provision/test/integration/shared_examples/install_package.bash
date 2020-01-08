# shellcheck disable=SC2154
load ../test_helper

setup_install_package() {
  local install_function="$1" name="$2" version="$3"

  mkdir -p "$PROVISION_TEST_DIR"

  local_root="$PROVISION_TEST_DIR/package-$name-local"
  rm -rf "$local_root"

  local_directory="$local_root/nested/directory"
  local_link_dest="$local_directory/$name"
}

teardown_install_package() {
  local install_function="$1" name="$2" version="$3"

  rm -rf "$local_root"
}

test_install_package_global() {
  local install_function="$1" name="$2" version="$3"

  "$install_function" \
    "$version"        \
    "$skip_use_sudo"  \
    "$skip_local_link"

  run "$name" --version
  assert_success
  assert_file_missing "$local_link_dest"
}

test_install_package_local_link() {
  local install_function="$1" name="$2" version="$3"
  assert_file_missing "$local_link_dest" # verify setup

  "$install_function" \
    "$version"        \
    "$skip_use_sudo"  \
    "$local_link_dest"

  run "$name" --version
  assert_success

  assert_valid_link_exists "$local_link_dest"
  run "$local_link_dest" --version
  assert_success
}

test_install_package_idempotance() {
  local install_function="$1" name="$2" version="$3"
  assert_file_missing "$local_link_dest" # verify setup

  "$install_function" \
    "$version"        \
    "$skip_use_sudo"  \
    "$local_link_dest"
  "$install_function" \
    "$version"        \
    "$skip_use_sudo"  \
    "$local_link_dest"

  run "$name" --version
  assert_success

  assert_valid_link_exists "$local_link_dest"
  run "$local_link_dest" --version
  assert_success
}
