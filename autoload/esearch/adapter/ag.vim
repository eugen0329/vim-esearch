if !exists('g:esearch#adapter#ag#options')
  let g:esearch#adapter#ag#options = ''
endif
if !exists('g:esearch#adapter#ag#bin')
  let g:esearch#adapter#ag#bin = 'ag'
endif

fu! esearch#adapter#ag#_options() abort
  if !exists('s:options')
    let s:options = {
          \ 'regex':   { 'p': ['--literal', ''],   's': ['>', 'r'] },
          \ 'case':    { 'p': ['--ignore-case', '--case-sensitive'], 's': ['>', 'c'] },
          \ 'word':    { 'p': ['',   '--word-regex'], 's': ['>', 'w'] },
          \ 'stringify':   function('esearch#util#stringify'),
          \ 'parametrize': function('esearch#util#parametrize'),
          \}
  endif
  return s:options
endfu

fu! esearch#adapter#ag#cmd(esearch, pattern, escape) abort
  let options = esearch#adapter#ag#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return g:esearch#adapter#ag#bin.' '.r.' '.c.' '.w.' --nogroup --nocolor --noheading ' .
        \ g:esearch#adapter#ag#options . ' -- ' .
        \ a:escape(a:pattern)  . ' ' . joined_paths
endfu

fu! esearch#adapter#ag#requires_pty() abort
  return 1
endfu

fu! esearch#adapter#ag#is_success(request) abort
  " https://github.com/ggreer/the_silver_searcher/issues/1298
  return a:request.status == 0
        \ || (a:request.status == 1 && empty(a:request.errors) && empty(a:request.data))
endfu
