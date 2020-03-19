" TODO reduce duplication with #ag

if !exists('g:esearch#adapter#ack#options')
  let g:esearch#adapter#ack#options = ''
endif
if !exists('g:esearch#adapter#ack#bin')
  let g:esearch#adapter#ack#bin = 'ack'
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

fu! esearch#adapter#ack#cmd(esearch, pattern, escape) abort
  let options = esearch#adapter#ack#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return g:esearch#adapter#ack#bin.' '.r.' '.c.' '.w.' -s --nogroup --nocolor -H' .
        \ g:esearch#adapter#ack#options . ' -- ' .
        \ a:escape(a:pattern)  . ' ' . joined_paths
endfu

fu! esearch#adapter#ack#requires_pty() abort
  return 1
endfu

fu! esearch#adapter#ack#is_success(request) abort
  return a:request.status == 0
endfu
