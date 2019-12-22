#!/bin/sh

crossplatform_realpath() {
  [ "$1" = '/*' ] && \ echo "$1" || echo "$PWD/${1#./}"
}

git_pull_or_clone() {
  repository="$1"
  directory="$2"

  if cd "$directory" >/dev/null 2>&1; then
    # if in a detached state - preserve it
    head_full_name="$(git rev-parse --abbrev-ref --symbolic-full-name HEAD)"
    if [ "$head_full_name" = 'HEAD' ]; then
      detached_at="$(git rev-parse HEAD)"
      git checkout master
      git pull --rebase
      git checkout "$detached_at"
    else
      git pull --rebase
    fi
  else
    git clone "$repository" "$directory"
  fi
  true
}

plugins_directory="${1:-"$(dirname "$(crossplatform_realpath "$0")")/../vim_plugins"}"
echo "$plugins_directory"

# Download pretty print
git_pull_or_clone https://github.com/thinca/vim-prettyprint "$plugins_directory/vim-prettyprint"
git -C "$plugins_directory/vim-prettyprint.vim" checkout d6060d2b1ff1cff71714e126addd3b10883ade12

# Download vimproc
git_pull_or_clone https://github.com/Shougo/vimproc.vim     "$plugins_directory/vimproc.vim"
git -C "$plugins_directory/vimproc.vim" checkout 89065f62883edb10a99aa1b1640d6d411907316b
(cd "$plugins_directory/vimproc.vim" && make)
