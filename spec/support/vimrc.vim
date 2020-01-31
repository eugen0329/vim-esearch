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

  return MatchesForPattern(found.pattern)
endfu

fu! MatchesForPattern(pattern) abort
  let hits = []
  try
    let old_search = @/
    let @/ = a:pattern
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

function! SynStack()  abort
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

fu! PreloadSyntax() abort
  norm! gg
  while 1
    norm! 10j
    redraw!

    if line('.') == line('$')
      break
    endif
  endwhile
endfu

fu! SyntaxAt(ln, column) abort
  let l:s = synID(a:ln, a:column, 0)
  let name = synIDattr(l:s, 'name')

  if empty(name)
    return ['ERR_EMPTY_SYNTAX_NAME', 'ERR_EMPTY_SYNTAX_NAME']
  endif
  " let links_to = synIDattr(synIDtrans(l:s), 'name')
  let hlstr = ''
  redir => hlstr
  silent exe 'hi '.name
  redir END
  let m = matchlist(hlstr, 'links to \(\w\+\)$')
  if len(m) < 2
    echoerr 'Vimrunner(SyntaxAt): Can''t parse hl link at ' . a:ln . ":" . a:column . ".\n"
          \ . "Inside line: \"" . escape(getline(a:ln), '"') . '"' . ".\n"
          \ . "              " . repeat(' ', a:column-1) . "^\n"
          \ . "`hi link ".name."` output contains: " . substitute(hlstr, "\\n", "\\\\n", 'g')
    let links_to = 'IS_NOT_A_LINK'
  else
    let links_to = m[1]
  endif

  return [name, links_to]
endfu

fu! InspectSyntax(places) abort
  call PreloadSyntax()

  let inspected = []
  for p in a:places
    norm! gg

    let found = []
    for [line_number, begin, end] in MatchesForPattern(p)

      for column_number in range(begin, end-1)
        let [name, links_to] = SyntaxAt(line_number, column_number)

        if empty(found)
          let found = [name, links_to]
        elseif found != [name, links_to]
          throw 'Vimrunner(InspectSyntax): Found different syntax at ' . line_number . ":" . column_number . ".\n"
                \ . "Line contains: \"" . getline(line_number) . "\"\n"
                \ . "                " . repeat(' ', column_number-1) . "^\n"
                \ . "Encountered earlier: " . string(found) . ".\n"
                \ . "Encountered now:     " . string([name, links_to]) . ".\n"
                \ . "While inspecting:    \"" . escape(p, '"') . '"'
        endif
      endfor
    endfor

    call add(inspected, found )
  endfor

  return inspected
endfu
