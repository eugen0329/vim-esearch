load ../test_helper
load shared_examples/install_prebuilt

setup() {
  setup_install_prebuilt 'install_prebuilt_rg' 'rg' '11.0.2'
}

teardown() {
  teardown_install_prebuilt 'install_prebuilt_rg' 'rg' '11.0.2'
}

### context 'prebuilt'

@test "install_prebuilt_rg with ln -> ./a-local-dir" {
  test_install_prebuilt_local 'install_prebuilt_rg' 'rg' '11.0.2'
}

@test "install_prebuilt_rg with ln -> ./a-global-dir" {
  test_install_prebuilt_global 'install_prebuilt_rg' 'rg' '11.0.2'
}

@test 'install_prebuilt_rg idempotance' {
  test_install_prebuilt_idempotance 'install_prebuilt_rg' 'rg' '11.0.2'
}
