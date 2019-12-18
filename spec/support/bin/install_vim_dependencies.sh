#!/bin/sh

crossplatform_realpath() {
    [ "$1" = '/*' ] && \ echo "$1" || echo "$PWD/${1#./}"
}

git_pull_or_clone() {
  local repository="$1"
  local directory="$2"
  local head_full_name

  if cd $directory >/dev/null 2>&1; then
    # if in a detached state - preserve it
    head_full_name="$(git rev-parse --abbrev-ref --symbolic-full-name HEAD)"
    if [ "$head_full_name" = 'HEAD' ]; then
      local detached_at
      detached_at="$(git rev-parse HEAD)"
      git checkout master
      git pull --rebase
      git checkout $detached_at
    else
      git pull --rebase
    fi
  else
    git clone $repository $directory
  fi
  true
}

directory_prefix="${1:-"$(dirname "$(crossplatform_realpath "$0")")/../vim_plugins"}"
echo $directory_prefix

git_pull_or_clone https://github.com/thinca/vim-prettyprint $directory_prefix/vim-prettyprint
git_pull_or_clone https://github.com/Shougo/vimproc.vim     $directory_prefix/vimproc.vim
git  -C $directory_prefix/vimproc.vim checkout 81f4fa5239705724a49fbecd3299ced843f4972f
cd $directory_prefix/vimproc.vim
make
cd -
