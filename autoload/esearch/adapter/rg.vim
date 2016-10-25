" TODO reduce duplication with #ag

fu! esearch#adapter#rg#options() abort
  if !exists('s:options')
    let s:options = {
    \ 'regex':   { 'p': ['--fixed-strings', ''], 's': ['>', 'r'] },
    \ 'case':    { 'p': ['--ignore-case', ''],   's': ['>', 'c'] },
    \ 'word':    { 'p': ['',   '--word-regexp'],  's': ['>', 'w'] },
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#rg#cmd(pattern, dir, escape, ...) abort
  let options = a:0 ? a:1 : esearch#adapter#rg#options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  return 'rg '.r.' '.c.' '.w.' --no-heading --color=never --column -- ' .
        \ a:escape(a:pattern)  . ' ' . fnameescape(a:dir)
endfu

fu! esearch#adapter#rg#is_broken_result(...) abort
  return call('esearch#adapter#ag#is_broken_result')
endfu

fu! esearch#adapter#rg#parse_results(...) abort
  return call('esearch#adapter#ag#parse_results', a:000)
endfu

fu! esearch#adapter#rg#requires_pty() abort
  return 1
endfu

function! esearch#adapter#rg#sid() abort
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
