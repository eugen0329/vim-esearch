#!/bin/sh
# shellcheck disable=SC2034

[ -n "$__LIB_SH_SOURCE_ONCE" ] && return 0; __LIB_SH_SOURCE_ONCE=1

current_os_release_id="$(awk -F= '$1=="ID" { print $2 }' /etc/os-release 2>/dev/null || true)"
current_os_release_id_like="$(awk -F= '$1=="ID_LIKE" { print $2 }' /etc/os-release 2>/dev/null || true)"
current_kernel_name="$(uname -s)"

apt_get_arguement_to_install_less="${apt_get_arguement_to_install_less:-"--no-install-recommends"}"
apk_argument_to_install_less="${apk_argument_to_install_less:-"--no-cache"}"
pip3_argument_to_install_less="${pip3_argument_to_install_less:-"--no-cache"}"

# Macros for better readability
skip_local_install=''
skip_global_install=''
skip_local_link=''
create_link_to_default_in_local_bin=1
create_link_to_default_in_global_bin=1
skip_create_link_to_default_in_local_bin=0
skip_create_link_to_default_in_global_bin=0
use_sudo='sudo'
dont_use_sudo=''

is_linux() {
  [ "$current_kernel_name" = 'Linux' ]
}

is_alpine_linux() {
  is_linux && [ "$current_os_release_id" = "alpine" ]
}

is_debian_or_debian_like_linux() {
  is_linux && \
    { [ "$current_os_release_id_like" = "debian" ] || [ "$current_os_release_id" = "debian" ]; }
}

is_osx() {
  [ "$current_kernel_name" = 'Darwin' ]
}

unarchive() {
  case $1 in
    # *.tar.bz2)   tar xvjf "$1"    ;;
    *.tar.gz)    tar xvzf "$1"    ;;
    # *.tar.xz)    tar xvJf "$1"    ;;
    # *.bz2)       bunzip2 "$1"     ;;
    # *.rar)       unrar x "$1"     ;;
    # *.gz)        gunzip "$1"      ;;
    *.tar)       tar xvf "$1"     ;;
    # *.tbz2)      tar xvjf "$1"    ;;
    # *.tgz)       tar xvzf "$1"    ;;
    *.zip)       unzip "$1"       ;;
    # *.Z)         uncompress "$1"  ;;
    # *.7z)        7z x "$1"        ;;
    # *.xz)        unxz "$1"        ;;
    # *.exe)       cabextract "$1"  ;;
    *.appimage)  chmod +x "$1"; ./"$1" --appimage-extract ;;
    *)           echo "\`$1': unrecognized file compression" && exit 1 ;;
  esac
}

create_global_executable_link() {
  local executable="$1"
  local link_dest="$2"
  local forced_flag='-f'

  if [ -n "$link_dest"  ]; then
    mkdir -p "$(dirname "$link_dest")"
    ln -s "$forced_flag" "$(command -v "$executable")" "$link_dest"
  else
    echo "Path must not be blank" && return 1
  fi
}

git_clone_and_checkout() {
  local repo="$1"
  local dest="$2"
  local version="$3"

  if [ "${forced:-0}" = '0' ] || ! is_git_repo "$dest" ; then
    rm -rfv "$dest"
    git clone "$repo" "$dest"
  fi

  [ -z "$version" ] || git -C "$dest" checkout  "$version"
}

is_git_repo() {
  git -C "$1" rev-parse --git-dir > /dev/null 2>&1
}

cp_no_overwrite() {
  [ -e "$2" ] || cp "$1" "$2"
}

install_versioned_prebuilt() {
  local name="$1"
  local version="$2"
  local src="$3"
  local dest="$4"
  local link_dest="$5"
  local sudo="${6:-}"
  local forced_flag='-f'
  local cp_command=cp

  # shellcheck disable=SC2059
  $sudo mkdir -p "$dest"
  # shellcheck disable=SC2059
  $sudo "$cp_command" "$binary_path_inside_unarchived_directory" "$dest/$name-$version"

  if [ -n "$link_dest" ] ; then
    # shellcheck disable=SC2059
    $sudo ln -s $forced_flag "$dest/$name-$version" "$link_dest"
  fi
}

install_prebuilt_from_downloadable_archive() {
  local name="$1"
  local version="$2"
  local dest="$3"
  local create_link_to_default="$4"
  local global_dest="$5"
  local create_global_link_to_default="$6"
  local archive_file="$7"
  local download_url="$8"
  local binary_path_inside_unarchived_directory="$9"
  local sudo="${10:-}"
  local temporary_directory="/tmp/$name-$version-installation"
  local link_dest global_link_dest
  [ "$create_link_to_default" = 0 ] || link_dest="$dest/$name"
  [ "$create_global_link_to_default" = 0 ] || global_link_dest="$global_dest/$name"


  (
    rm -frv "$temporary_directory"
    mkdir -p  "$temporary_directory"
    cd  "$temporary_directory" || exit 3
    wget -N "$download_url"

    unarchive "$archive_file"

    [ -z "$dest" ] ||                            \
      install_versioned_prebuilt                 \
      "$name"                                    \
      "$version"                                 \
      "$binary_path_inside_unarchived_directory" \
      "$dest"                                    \
      "$link_dest"

    [ -z "$global_dest" ] ||                     \
      install_versioned_prebuilt                 \
      "$name"                                    \
      "$version"                                 \
      "$binary_path_inside_unarchived_directory" \
      "$global_dest"                             \
      "$global_link_dest"
  )
  rm -frv "$temporary_directory"
}
