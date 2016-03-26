" TODO reduce duplication with #ag

fu! esearch#adapter#pt#options() abort
  if !exists('s:options')
    let s:options = {
    \ 'regex':   { 'p': ['', '-e'],   's': ['>', 'r'] },
    \ 'case':    { 'p': ['-i', ''],   's': ['>', 'c'] },
    \ 'word':    { 'p': ['',   '-w'], 's': ['>', 'w'] },
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#pt#cmd(pattern, dir, escape, ...) abort
  let options = a:0 ? a:1 : esearch#adapter#pt#options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  return "pt ".r." ".c." ".w." --nogroup --nocolor --column -- " .
        \ a:escape(a:pattern)  . " " . a:escape(a:dir)
endfu

fu! esearch#adapter#pt#is_broken_result(...) abort
  return call('esearch#adapter#ag#is_broken_result')
endfu

fu! esearch#adapter#pt#parse_results(...) abort
  return call('esearch#adapter#ag#parse_results', a:000)
endfu

fu! esearch#adapter#pt#requires_pty()
  return 1
endfu

function! esearch#adapter#pt#sid()
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
