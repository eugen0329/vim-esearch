load ../test_helper
load shared_examples/install_package

setup() {
  setup_install_package 'install_package_ragel' 'ragel' 'latest'
}

teardown() {
  teardown_install_package  'install_package_ragel' 'ragel' 'latest'
}

### context 'package'

@test "install_package_ragel globally" {
  test_install_package_global 'install_package_ragel' 'ragel' 'latest'
}

@test "install_package_ragel with ln -> ./local-dir" {
  test_install_package_local_link 'install_package_ragel' 'ragel' 'latest'
}

@test "install_package_ragel idempotance" {
  test_install_package_idempotance 'install_package_ragel' 'ragel' 'latest'
}
