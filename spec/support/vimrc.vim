" VIMRUNNER COPYPASTE START
"""""""""""""""""""""""""""
set nocompatible

filetype plugin on
filetype indent on
syntax on

set noswapfile nobackup

" remove default ~/.vim directories to avoid loading plugins
set runtimepath-=~/.vim
set runtimepath-=~/.vim/after
"""""""""""""""""""""""""""
" VIMRUNNER COPYPASTE END

" Prevents a bug during testing when X11 window is gradually squeezed after each
" closing of the current vim tab with search results (which leads to showing and
" hiding of tabline when showtabline=1 and reducing of X11 window height).
" Assigning to 2 prevents it from hiding (no matter how many tabs left) and
" therefore fixes vim bug.
set showtabline=2
