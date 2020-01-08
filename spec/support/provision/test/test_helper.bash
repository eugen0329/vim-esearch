load /provision/test/vendor/default_test_helper.bash
provision_dir=/provision verbose=0 load /provision/__provision.sh

assert_file_exists() {
  assert [ -f "$1" ]
}

assert_file_missing() {
  assert [ ! -f "$1" ]
}

assert_output_includes() {
  # shellcheck disable=SC2154
  if ! echo "$output" | grep "$1" 1>/dev/null 2>&1; then
    flunk "Expected $output to include $1"
  fi
}

assert_valid_link_exists() {
  [ -L "$1" ] && [ -e "$1" ] && { [ -z "${2:-}" ] || [ "$(readlink "$1")" = "$2" ]; }
}

assert_output_includes() {
  # shellcheck disable=SC2154
  if ! echo "$output" | grep "$1" 1>/dev/null 2>&1; then
    flunk "Expected $output to include $1"
  fi
}

assert_valid_link_exists() {
  [ -L "$1" ] && [ -e "$1" ] && { [ -z "${2:-}" ] || [ "$(readlink "$1")" = "$2" ]; }
}
