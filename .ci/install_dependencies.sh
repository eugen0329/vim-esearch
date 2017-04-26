ORIG_DIR=`pwd`

# Install vim deps
git clone https://github.com/thinca/vim-prettyprint ./.dep/vim-prettyprint
git clone https://github.com/Shougo/vimproc.vim     ./.dep/vimproc.vim
cd ./.dep/vimproc.vim
make
cd $ORIG_DIR
