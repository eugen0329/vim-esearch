# shellcheck disable=SC2154
load ../test_helper

setup_install_prebuilt() {
  local install_prebuilt_function="$1" name="$2" version="$3"

  mkdir -p "$PROVISION_TEST_DIR"

  local_root="$PROVISION_TEST_DIR/prebuilt-$name-local"
  global_root="$PROVISION_TEST_DIR/prebuilt-$name-global"
  rm -rf "$local_root" "$global_root"

  local_bin="$local_root/nested/directory"
  global_bin="$global_root/nested/directory"
  local_default_executable="$local_bin/$name"
  global_default_executable="$global_bin/$name"

  tmp_was="$(ls /tmp)"
}

teardown_install_prebuilt() {
  local install_prebuilt_function="$1" name="$2" version="$3"

  assert_equal "$tmp_was" "$(ls /tmp)" # verify cleanup is done well
  rm -rf "$local_root" "$global_root"
}

test_install_prebuilt_local() {
  local install_prebuilt_function="$1" name="$2" version="$3"

  "$install_prebuilt_function"                  \
    "$version"                                  \
    "$local_bin"                                \
    "$create_link_to_default_in_local_bin"

    run "$local_bin/$name-$version" --version
    assert_success
    assert_valid_link_exists "$local_default_executable" "$local_bin/$name-$version"

    run "$global_bin/$name-$version" --version
    assert_failure
    assert_file_missing "$global_default_executable"
    assert_file_missing "$global_bin/$name-$version"
}

test_install_prebuilt_global() {
  local install_prebuilt_function="$1" name="$2" version="$3"

  "$install_prebuilt_function"                  \
    "$version"                                  \
    "$skip_local_install"                       \
    "$skip_create_link_to_default_in_local_bin" \
    "$global_bin"                               \
    "$create_link_to_default_in_global_bin"

    run "$local_bin/$name-$version" --version
    assert_failure
    assert_file_missing "$local_default_executable"
    assert_file_missing "$local_bin/$name-$version"

    run "$global_bin/$name-$version" --version
    assert_success
    assert_valid_link_exists "$global_default_executable" "$global_bin/$name-$version"
}

test_install_prebuilt_idempotance() {
  local install_prebuilt_function="$1" name="$2" version="$3"

  "$install_prebuilt_function"                  \
    "$version"                                  \
    "$local_bin"                                \
    "$create_link_to_default_in_local_bin"      \
    "$global_bin"                               \
    "$create_link_to_default_in_global_bin"
  "$install_prebuilt_function"                  \
    "$version"                                  \
    "$local_bin"                                \
    "$create_link_to_default_in_local_bin"      \
    "$global_bin"                               \
    "$create_link_to_default_in_global_bin"

  run "$local_bin/$name-$version" --version
  assert_success
  assert_valid_link_exists "$local_default_executable" "$local_bin/$name-$version"

  run "$global_bin/$name-$version" --version
  assert_success
  assert_valid_link_exists "$global_default_executable" "$global_bin/$name-$version"
}
