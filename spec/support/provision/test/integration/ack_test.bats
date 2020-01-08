load ../test_helper
load shared_examples/install_package
# load shared_examples/install_prebuilt

setup() {
  setup_install_package 'install_package_ack' 'ack' 'latest'
  # setup_install_prebuilt 'install_prebuilt_ack' 'ack' '0.4.3'
}

teardown() {
  teardown_install_package  'install_package_ack' 'ack' 'latest'
  # teardown_install_prebuilt 'install_prebuilt_ack' 'ack' '0.4.3'
}

### context 'package'

@test "install_package_ack globally" {
  test_install_package_global 'install_package_ack' 'ack' 'latest'
}

@test "install_package_ack with ln -> ./local-dir" {
  test_install_package_local_link 'install_package_ack' 'ack' 'latest'
}

@test "install_package_ack idempotance" {
  test_install_package_idempotance 'install_package_ack' 'ack' 'latest'
}
