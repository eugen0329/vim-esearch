" TODO reduce duplication with #ag

if !exists('g:esearch#adapter#pt#options')
  let g:esearch#adapter#pt#options = ''
endif
if !exists('g:esearch#adapter#pt#bin')
  let g:esearch#adapter#pt#bin = 'pt'
endif

fu! esearch#adapter#pt#_options() abort
  if !exists('s:options')
    let s:options = {
    \ 'regex':   { 'p': ['', '-e'],   's': ['>', 'r'] },
    \ 'case':    { 'p': ['', '--ignore-case'],   's': ['c', '>'] },
    \ 'word':    { 'p': ['',   '-w'], 's': ['>', 'w'] },
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#pt#cmd(esearch, pattern, escape) abort
  let options = esearch#adapter#pt#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return g:esearch#adapter#pt#bin.' '.r.' '.c.' '.w.' --nogroup --nocolor ' .
        \ g:esearch#adapter#pt#options . ' -- ' .
        \ a:escape(a:pattern)  . ' ' . joined_paths
endfu

fu! esearch#adapter#pt#set_results_parser(esearch) abort
  let a:esearch.parse = function('esearch#adapter#ag_like#parse')
  let a:esearch.format = g:esearch#adapter#ag_like#multiple_files_search_format
  let a:esearch.expand_filename = function('esearch#adapter#ag_like#expand_filename')
endfu

fu! esearch#adapter#pt#requires_pty() abort
  return 1
endfu
