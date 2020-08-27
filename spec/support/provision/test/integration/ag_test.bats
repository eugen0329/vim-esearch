load ../test_helper
load shared_examples/install_package
# load shared_examples/install_prebuilt

setup() {
  setup_install_package 'install_package_ag' 'ag' 'latest'
  # setup_install_prebuilt 'install_prebuilt_ag' 'ag' 'latest'
}

teardown() {
  teardown_install_package  'install_package_ag' 'ag' 'latest'
  # teardown_install_prebuilt 'install_prebuilt_ag' 'ag' 'latest'
}

### context 'package'

@test "install_package_ag globally" {
  test_install_package_global 'install_package_ag' 'ag' 'latest'
}

@test "install_package_ag with ln -> ./local-dir" {
  test_install_package_local_link 'install_package_ag' 'ag' 'latest'
}

@test "install_package_ag idempotance" {
  test_install_package_idempotance 'install_package_ag' 'ag' 'latest'
}
