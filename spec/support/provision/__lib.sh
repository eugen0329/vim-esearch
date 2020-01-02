#!/bin/sh
# shellcheck disable=SC2034

[ -n "$__LIB_SH_SOURCE_ONCE" ] && return 0; __LIB_SH_SOURCE_ONCE=1

set -eu

running_script_absolute_path="$([ "$0" = '/*' ] && \ echo "$0" || echo "$PWD/${0#./}")"
provision_directory="$(dirname "$running_script_absolute_path")"

apt_get_arguement_to_install_less='--no-install-recommends'
apk_argument_to_install_less='--no-cache'
pip3_argument_to_install_less='--no-cache'
unarchive_tar="tar xvfz '%s'"
unarchive_zip="unzip '%s'"

CURRENT_OS_RELEASE_ID="$(awk -F= '$1=="ID" { print $2 }' /etc/os-release 2>/dev/null || true)"
CURRENT_OS_RELEASE_ID_LIKE="$(awk -F= '$1=="ID_LIKE" { print $2 }' /etc/os-release 2>/dev/null || true)"
CURRENT_KERNEL_NAME="$(uname -s)"

# Macros for better readability
skip_local_install=''
skip_global_install=''
# install_global=1
# install_local=1
dont_use_sudo=''
use_sudo='sudo'
create_link_to_default_in_local_directory=1
pull_all_branches=''
dont_checkout=''

is_linux() {
  [ "$CURRENT_KERNEL_NAME" = 'Linux' ]
}

is_alpine_linux() {
  is_linux && [ "$CURRENT_OS_RELEASE_ID" = "alpine" ]
}

is_debian_linux() {
  is_linux && [ "$CURRENT_OS_RELEASE_ID" = "debian" ]
}

is_debian_or_debian_like_linux() {
  is_linux && \
    { [ "$CURRENT_OS_RELEASE_ID_LIKE" = "debian" ] || [ "$CURRENT_OS_RELEASE_ID" = "debian" ]; }
}

is_osx() {
  [ "$CURRENT_KERNEL_NAME" = 'Darwin' ]
}

create_symlink() {
  executable="$1"
  link_path="$2"

  if [ -n "$link_path"  ]; then
    mkdir -p "$(dirname "$link_path")"
    ln -sf "$(which "$executable")" "$link_path"
  else
    echo "Path must not be blank" && return 1
  fi
}

git_clone_and_checkout() {
  repository_url="$1"
  clone_path="$2"
  branch="${3:-'master'}"
  commit_hash="${4:-"$dont_checkout"}"
  if [ -e "$clone_path" ]; then
    echo 'do nothing for now. TODO'
  else
    if [ "$branch" = "$pull_all_branches" ]; then
      git clone "$repository_url" "$clone_path"
    else
      git clone -b "$branch" --single-branch "$repository_url" "$clone_path"
    fi
  fi

  [ "$commit_hash" = "$dont_checkout" ] || git -C "$clone_path" checkout  "$commit_hash"
}

is_inside_git_repository() {
  git rev-parse --git-dir > /dev/null 2>&1
}

install_prebuilt_from_downloadable_archive() {
  name="$1"
  version="$2"
  local_directory_path="$3"
  global_directory_path="$4"
  create_link_to_default_in_local_directory="$5"
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

    if [ -n "$local_directory_path" ]; then
      cp "$binary_path_inside_unarchived_directory" "$local_directory_path/$name-$version"
    fi

    if [ "$create_link_to_default_in_local_directory" = '1' ]; then
      ln -fs "$local_directory_path/$name-$version" "$local_directory_path/$name"
    fi

    if [ -n "$global_directory_path" ]; then
      cp "$binary_path_inside_unarchived_directory" "$global_directory_path/$name-$version"
    fi
  )
  rm -frv "$temporary_directory"
}
