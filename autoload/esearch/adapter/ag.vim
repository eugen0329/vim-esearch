fu! esearch#adapter#ag#options()
  if !exists('s:options')
    let s:options = {
    \ 'regex':   { 'p': ['-Q', ''],   's': ['>', 'r'] },
    \ 'case':    { 'p': ['-i', '-s'], 's': ['>', 'c'] },
    \ 'word':    { 'p': ['',   '-w'], 's': ['>', 'w'] },
    \ 'stringify':   function('<SID>stringify'),
    \ 'parametrize': function('<SID>parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#ag#cmd(pattern, dir) abort
  let r = s:options.parametrize('regex')
  let c = s:options.parametrize('case')
  let w = s:options.parametrize('word')
  return "ag ".r." ".c." ".w." --nogroup --nocolor --column -- " .
        \ esearch#util#shellescape(a:pattern)  . " " . esearch#util#shellescape(a:dir)
endfu

" Used to build the query
fu! s:parametrize(key, ...) dict abort
  let option_index = g:esearch[a:key]
  return self[a:key]['p'][option_index]
endfu

" Used in cmdline prompt
fu! s:stringify(key, ...) dict abort
  let option_index = g:esearch[a:key]
  return self[a:key]['s'][option_index]
endfu
