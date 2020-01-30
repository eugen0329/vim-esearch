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

fu! Matches(group) abort
  let found = {}

  for m in getmatches()
    if m.group == a:group
      let found = m
      break
    endif
  endfor

  if empty(found)
    return []
  endif

  let hits = []
  try
    let old_search = @/
    let @/ = found.pattern
    let nowhere = ''
		redir => nowhere
    silent %s//\=add(hits, [line('.'), col('.'), col('.')+len(submatch(0))])/gn
    redir END
  catch /Vim(substitute):E486: Pattern not found/
  finally
    let @/ = old_search
  endtry

  return hits
endfu


function! VimrunnerEvaluate(expr)
  try
    return string(eval(a:expr))
  catch
    return v:exception
  endtry
endfunction
