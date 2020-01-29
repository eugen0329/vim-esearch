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

fu! Matches(pattern) abort

  try
    let old_search = @/
    let @/ = a:pattern

    let hits = []
    let nowhere = ''
		redir => nowhere
    silent %s//\=add(hits, [line('.'), col('.'), col('.')+len(submatch(0))])/gn
    redir END
  finally
    let @/ = old_search
  endtry

  return hits
endfu


function! VimrunnerEvaluate(expr)
  try
    let output = eval(a:expr)
  catch
    let output = v:exception
  endtry

  return [output]
endfunction
