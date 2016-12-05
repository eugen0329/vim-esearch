" TODO reduce duplication with #ag

if !exists('g:esearch#adapter#ack#options')
  let g:esearch#adapter#ack#options = '--sort-files'
endif

fu! esearch#adapter#ack#_options() abort
  if !exists('s:options')
    let s:options = {
    \ 'regex':   { 'p': ['-Q', ''],   's': ['>', 'r'] },
    \ 'case':    { 'p': ['-i', '-s'], 's': ['>', 'c'] },
    \ 'word':    { 'p': ['',   '-w'], 's': ['>', 'w'] },
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#ack#cmd(pattern, dir, escape, ...) abort
  let options = a:0 ? a:1 : esearch#adapter#ack#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  return 'ack '.r.' '.c.' '.w.' -s --nogroup --nocolor --column ' .
        \ g:esearch#adapter#ack#options . ' -- ' .
        \ a:escape(a:pattern)  . ' ' . fnameescape(a:dir)
endfu

fu! esearch#adapter#ack#is_broken_result(...) abort
  return call('esearch#adapter#ag#is_broken_result')
endfu

fu! esearch#adapter#ack#parse_results(...) abort
  return call('esearch#adapter#ag#parse_results', a:000)
endfu

fu! esearch#adapter#ack#requires_pty() abort
  return 1
endfu

function! esearch#adapter#ack#sid() abort
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
