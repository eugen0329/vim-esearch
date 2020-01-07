# Vendor code, taken from another which use bats (de-facto standard
# outlook of a test_helper.bash)
################################################################

# guard against executing this block twice due to bats internals
if [ -z "$PROVISION_TEST_DIR" ]; then
  PROVISION_TEST_DIR="${BATS_TMPDIR}/provision_test_dir"
  export PROVISION_TEST_DIR="$(mktemp -d "${PROVISION_TEST_DIR}.XXX" 2>/dev/null || echo "$PROVISION_TEST_DIR")"

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

  PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
  export PATH
fi

teardown() {
  rm -rf "$PROVISION_TEST_DIR"
}

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed "s:${PROVISION_TEST_DIR}:TEST_DIR:g" >&2
  return 1
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    flunk "command failed with exit status $status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_not_equal() {
  if [ "$1" = "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then return 0; fi
    done
    flunk "expected line \`$1'"
  fi
}

refute_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then
        flunk "expected to not find line \`$line'"
      fi
    done
  fi
}

assert() {
  if ! "$@"; then
    flunk "failed: $@"
  fi
}

################################################################

assert_file_exists() {
  assert [ -f "$1" ]
}

assert_file_missing() {
  assert [ ! -f "$1" ]
}

assert_output_includes() {
  if ! echo "$output" | grep "$1" 2>&1 1>/dev/null; then
    flunk "Expected $output to include $1"
  fi
}

assert_valid_link_exists() {
  [ -L "$1" ] && [ -e "$1" ] && { [ -z "${2:-}" ] || [ "$(readlink "$1")" = "$2" ]; }
}

provision_directory=/provision load /provision/__provision.sh
set +x
