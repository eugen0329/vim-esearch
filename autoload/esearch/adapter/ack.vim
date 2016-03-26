" TODO reduce duplication with #ag

fu! esearch#adapter#ack#options() abort
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
  let options = a:0 ? a:1 : esearch#adapter#ack#options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  return "ack ".r." ".c." ".w." -s --nogroup --nocolor --column -- " .
        \ a:escape(a:pattern)  . " " . a:escape(a:dir)
endfu

fu! esearch#adapter#ack#is_broken_result(...) abort
  return call('esearch#adapter#ag#is_broken_result')
endfu

fu! esearch#adapter#ack#parse_results(...) abort
  return call('esearch#adapter#ag#parse_results', a:000)
endfu

fu! esearch#adapter#ack#requires_pty()
  return 1
endfu

function! esearch#adapter#ack#sid()
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
