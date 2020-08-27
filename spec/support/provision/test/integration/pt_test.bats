load ../test_helper
load shared_examples/install_prebuilt
load shared_examples/install_package

setup() {
  setup_install_prebuilt 'install_prebuilt_pt' 'pt' '2.2.0'
}

teardown() {
  teardown_install_prebuilt 'install_prebuilt_pt' 'pt' '2.2.0'
}

### context 'prebuilt'

@test "install_prebuilt_rg with ln -> ./a-local-dir" {
  ! is_alpine_linux || skip "Only built from scratch is working on alpine"

  test_install_prebuilt_local 'install_prebuilt_pt' 'pt' '2.2.0'
}

@test "install_prebuilt_rg with ln -> ./a-global-dir" {
  ! is_alpine_linux || skip "Only built from scratch is working on alpine"

  test_install_prebuilt_global 'install_prebuilt_pt' 'pt' '2.2.0'
}

@test "pt brebuilt binary install idempotance" {
  ! is_alpine_linux || skip "Only built from scratch is working on alpine"

  test_install_prebuilt_idempotance 'install_prebuilt_pt' 'pt' '2.2.0'
}
