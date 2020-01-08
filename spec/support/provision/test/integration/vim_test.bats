load ../test_helper
load shared_examples/install_package
# load shared_examples/install_prebuilt

setup() {
  if is_osx; then name='mvim'
  else            name='gvim'
  fi

  setup_install_package 'install_package_vim' "$name" 'latest'
  # setup_install_prebuilt 'install_prebuilt_vim' "$name" 'latest'
}

teardown() {
  teardown_install_package  'install_package_vim' "$name" 'latest'
  # teardown_install_prebuilt 'install_prebuilt_vim' "$name" 'latest'
}

### context 'package'

@test "install_package_vim globally" {
  test_install_package_global 'install_package_vim' "$name" 'latest'
}

@test "install_package_vim with ln -> ./local-dir" {
  test_install_package_local_link 'install_package_vim' "$name" 'latest'
}

@test "install_package_vim idempotance" {
  test_install_package_idempotance 'install_package_vim' "$name" 'latest'
}
