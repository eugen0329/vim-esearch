#!/bin/sh
# shellcheck disable=SC2034

apt_get_arguement_to_install_less='--no-install-recommends'
apk_argument_to_install_less='--no-cache'
pip3_argument_to_install_less='--no-cache'
unarchive_tar="tar xvfz '%s'"
unarchive_zip="unzip '%s'"

# Macros for readability
skip_install_local=''
skip_global_install=''
install_global=1
install_local=1
dont_use_sudo=''
using_sudo='sudo'
link_to_default_in_local_directory=1

get_current_os_release_id() {
  awk -F= '$1=="ID_LIKE" { found=1; print $2 }; END {exit !found}' /etc/os-release || \
    awk -F= '$1=="ID" { found=1; print $2 } END {exit !found}' /etc/os-release
}
crossplatform_realpath() {
    [ "$1" = '/*' ] && \ echo "$1" || echo "$PWD/${1#./}"
}
CURRENT_OS_RELEASE_ID="$(get_current_os_release_id)"
CURRENT_KERNEL_NAME="$(uname -s)"
provision_directory="$(dirname "$(crossplatform_realpath "$0")")"
bin_directory="${1:-"$(dirname "$(crossplatform_realpath "$0")")/../bin"}"
mkdir -p "$bin_directory"

is_linux() {
  [ "$CURRENT_KERNEL_NAME" = 'Linux' ]
}

is_alpine_linux() {
  is_linux && [ "$CURRENT_OS_RELEASE_ID" = "alpine" ]
}

is_debian_linux() {
  is_linux && [ "$CURRENT_OS_RELEASE_ID" = "debian" ]
}

is_osx() {
  [ "$CURRENT_KERNEL_NAME" = 'Darwin' ]
}

create_executable_symlink_if_path_given() {
  executable="$1"
  create_link_to="$2"

  if [ -n "$create_link_to"  ]; then
    mkdir -p "$(dirname "$create_link_to")"
    ln -sf "$(which "$executable")" "$create_link_to"
  fi
}

install_prebuilt_from_downloadable_archive() {
  name="$1"
  version="$2"
  into_local_directory="$3"
  into_global_directory="$4"
  link_to_default_in_local_directory="$5"
  archive_file="$6"
  download_url="$7"
  binary_path_inside_unarchived_directory="$8"
  unarchive_command="$9"
  sudo="${10}"
  temporary_directory="/tmp/$name-$version"

  (
  rm -frv "$temporary_directory"
  mkdir -p  "$temporary_directory"
  cd        "$temporary_directory"
  wget -N "$download_url"

  # shellcheck disable=SC2059
  unarchive=$(printf "$unarchive_command" "$archive_file")
  eval "$unarchive"

  if [ -n "$into_local_directory" ]; then
    cp "$binary_path_inside_unarchived_directory" "$into_local_directory/$name-$version"
  fi

  if [ "$link_to_default_in_local_directory" = '1' ]; then
    ln -fs "$into_local_directory/$name-$version" "$into_local_directory/$name"
  fi

  if [ -n "$into_global_directory" ]; then
    cp "$binary_path_inside_unarchived_directory" "$into_global_directory/$name-$version"
  fi
  )
  rm -frv "$temporary_directory"
}

install_prebuilt_rg() {
  version="$1"
  into_local_directory="$2"
  into_global_directory="$3"
  link_to_default_in_local_directory="$4"
  if is_linux; then
    directory_inside_archive="ripgrep-$version-x86_64-unknown-linux-musl"
  elif is_osx; then
    directory_inside_archive="ripgrep-$version-x86_64-apple-darwin"
  else
    echo "Unsupported platform" && return 1
  fi
  archive_file="$directory_inside_archive.tar.gz"
  download_url="https://github.com/BurntSushi/ripgrep/releases/download/$version/$archive_file"
  binary_path_inside_unarchived_directory="$directory_inside_archive/rg"
  unarchive_command="$unarchive_tar"
  sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'rg'                                       \
    "$version"                                 \
    "$into_local_directory"                    \
    "$into_global_directory"                   \
    "$link_to_default_in_local_directory"      \
    "$archive_file"                            \
    "$download_url"                            \
    "$binary_path_inside_unarchived_directory" \
    "$unarchive_command"                       \
    "$sudo"
}

install_prebuilt_pt() {
  version="$1"
  into_local_directory="$2"
  into_global_directory="$3"
  link_to_default_in_local_directory="$4"
  if is_linux; then
    directory_inside_archive="pt_linux_amd64"
    archive_file="$directory_inside_archive.tar.gz"
    unarchive_command="$unarchive_tar"
  elif is_osx; then
    directory_inside_archive="pt_darwin_amd64"
    archive_file="$directory_inside_archive.zip"
    unarchive_command="$unarchive_zip"
  else
    echo "Unsupported platform" && return 1
  fi
  download_url="https://github.com/monochromegane/the_platinum_searcher/releases/download/v$version/$archive_file"
  binary_path_inside_unarchived_directory="$directory_inside_archive/pt"
  sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'pt'                                       \
    "$version"                                 \
    "$into_local_directory"                    \
    "$into_global_directory"                   \
    "$link_to_default_in_local_directory"      \
    "$archive_file"                            \
    "$download_url"                            \
    "$binary_path_inside_unarchived_directory" \
    "$unarchive_command"                       \
    "$sudo"
}

install_prebuilt_neovim() {
  version="${1:-'0.4.3'}"
  into_local_directory="$2"
  into_global_directory="$3"
  link_to_default_in_local_directory="$4"
  if is_linux; then
    archive_file='nvim.appimage'
    binary_path_inside_unarchived_directory="squashfs-root/usr/bin/nvim"
    unarchive_command="chmod +x '$archive_file'; ./'$archive_file' --appimage-extract"
  elif is_osx; then
    archive_file='nvim-macos.tar.gz'
    unarchive_command="$unarchive_tar"
  else
    echo "Unsupported platform" && return 1
  fi
  download_url="https://github.com/neovim/neovim/releases/download/v$version/$archive_file"
  sudo="$dont_use_sudo"

  install_prebuilt_from_downloadable_archive   \
    'nvim'                                     \
    "$version"                                 \
    "$into_local_directory"                    \
    "$into_global_directory"                   \
    "$link_to_default_in_local_directory"      \
    "$archive_file"                            \
    "$download_url"                            \
    "$binary_path_inside_unarchived_directory" \
    "$unarchive_command"                       \
    "$sudo"
}

install_package_ack() {
  name=ack
  version="$1"
  sudo="$2"
  create_link_to="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_linux; then
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" ack-grep
    $sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep || true
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" ack
  elif os_osx; then
    brew install ack
  else
    echo 'Unsupported platform' && return 1
  fi
  create_executable_symlink_if_path_given "$name" "$create_link_to"
}

install_package_ag() {
  name=ag
  version="$1"
  sudo="$2"
  create_link_to="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_linux; then
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" silversearcher-ag
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" the_silver_searcher
  elif os_osx; then
    brew install the_silver_searcher
  else
    echo 'Unsupported platform' && return 1
  fi
  create_executable_symlink_if_path_given "$name" "$create_link_to"
}

install_package_vim() {
  name=vim
  version="$1"
  sudo="$2"
  create_link_to="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_linux; then
    $sudo add-apt-repository ppa:jonathonf/vim -y
    $sudo apt update -y
    $sudo apt-get install -y "$apt_get_arguement_to_install_less" vim-gtk
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" gvim
  elif os_osx; then
    brew update --verbose
    brew install --build-from-source "$provision_directory/brew_formulae/macvim.rb" -- --with-override-system-vi
  else
    echo 'Unsupported platform' && return 1
  fi
  create_executable_symlink_if_path_given "$name" "$create_link_to"
}

install_package_neovim() {
  name=nvim
  version="$1"
  sudo="$2"
  create_link_to="${3:-}"

  if [ "$version" != 'latest' ]; then
    echo 'Unsupported yet' && return 1
  fi

  if is_debian_linux; then
    echo 'Unsupported yet' && return 1
  elif is_alpine_linux; then
    apk add "$apk_argument_to_install_less" neovim
  elif os_osx; then
    echo 'Unsupported yet' && return 1
  else
    echo 'Unsupported platform' && return 1
  fi
  create_executable_symlink_if_path_given "$name" "$create_link_to"
}

set -eux
