load ../test_helper
load shared_examples/install_package
load shared_examples/install_prebuilt

setup() {
  setup_install_package 'install_package_neovim' 'nvim' 'latest'
  setup_install_prebuilt 'install_prebuilt_neovim' 'nvim' '0.4.3'
}

teardown() {
  teardown_install_package  'install_package_neovim' 'nvim' 'latest'
  teardown_install_prebuilt 'install_prebuilt_neovim' 'nvim' '0.4.3'
}

### context 'package'

@test "install_package_neovim globally" {
  test_install_package_global 'install_package_neovim' 'nvim' 'latest'
}

@test "install_package_neovim with ln -> ./local-dir" {
  test_install_package_local_link 'install_package_neovim' 'nvim' 'latest'
}

@test "install_package_neovim idempotance" {
  test_install_package_idempotance 'install_package_neovim' 'nvim' 'latest'
}

### context 'prebuilt'

@test "install_prebuilt_nvim with ln -> ./a-local-dir" {
  ! is_alpine_linux || skip "appimages are not supported on alpine"

  test_install_prebuilt_local 'install_prebuilt_nvim' 'nvim' 'latest'
}

@test "install_prebuilt_nvim with ln -> ./a-global-dir" {
  ! is_alpine_linux || skip "appimages are not supported on alpine"

  test_install_prebuilt_global 'install_prebuilt_nvim' 'nvim' 'latest'
}

@test 'install_prebuilt_nvim idempotance' {
  ! is_alpine_linux || skip "appimages are not supported on alpine"

  test_install_prebuilt_idempotance 'install_prebuilt_nvim' 'nvim' 'latest'
}
