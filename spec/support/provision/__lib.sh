#!/bin/sh
# shellcheck disable=SC2034

[ ! -z "$PROVISION_LIB_SOURCE_ONCE" ] && return 0; PROVISION_LIB_SOURCE_ONCE=1

set -eu

running_script_absolute_path="$([ "$0" = '/*' ] && \ echo "$0" || echo "$PWD/${0#./}")"
provision_directory="$(dirname "$running_script_absolute_path")"
bin_directory="${1:-"$provision_directory/../bin"}"

apt_get_arguement_to_install_less='--no-install-recommends'
apk_argument_to_install_less='--no-cache'
pip3_argument_to_install_less='--no-cache'
unarchive_tar="tar xvfz '%s'"
unarchive_zip="unzip '%s'"

CURRENT_OS_RELEASE_ID="$(awk -F= '$1=="ID" { print $2 }' /etc/os-release)"
CURRENT_OS_RELEASE_ID_LIKE="$(awk -F= '$1=="ID_LIKE" { print $2 }' /etc/os-release)"
CURRENT_KERNEL_NAME="$(uname -s)"

# Macros for better readability
skip_install_local=''
skip_global_install=''
install_global=1
install_local=1
dont_use_sudo=''
using_sudo='sudo'
link_to_default_in_local_directory=1

is_linux() {
  [ "$CURRENT_KERNEL_NAME" = 'Linux' ]
}

is_alpine_linux() {
  is_linux && [ "$CURRENT_OS_RELEASE_ID" = "alpine" ]
}

is_debian_linux() {
  is_linux && [ "$CURRENT_OS_RELEASE_ID" = "debian" ]
}

is_debian_or_like_linux() {
  is_linux && \
    { [ "$CURRENT_OS_RELEASE_ID_LIKE" = "debian" ] || [ "$CURRENT_OS_RELEASE_ID" = "debian" ]; }
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
