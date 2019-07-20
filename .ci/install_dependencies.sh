# Install vim deps
git clone https://github.com/thinca/vim-prettyprint ./.dep/vim-prettyprint
git clone https://github.com/Shougo/vimproc.vim     ./.dep/vimproc.vim
git  -C ./.dep/vimproc.vim checkout 81f4fa5239705724a49fbecd3299ced843f4972f
cd ./.dep/vimproc.vim
make
cd -
