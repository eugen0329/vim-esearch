" TODO reduce duplication with #ag

if !exists('g:esearch#adapter#rg#options')
  let g:esearch#adapter#rg#options = ''
endif
if !exists('g:esearch#adapter#rg#bin')
  let g:esearch#adapter#rg#bin = 'rg'
endif
if !exists('g:esearch#adapter#rg#pcre2')
  " let g:esearch#adapter#rg#pcre2 = '--pcre2'
  let g:esearch#adapter#rg#pcre2 = ''
endif

fu! esearch#adapter#rg#_options() abort
  if !exists('s:options')
    let s:options = {
    \ 'regex':   { 'p': ['--fixed-strings', g:esearch#adapter#rg#pcre2], 's': ['>', 'r'] },
    \ 'case':    { 'p': ['--ignore-case', ''],   's': ['>', 'c'] },
    \ 'word':    { 'p': ['',   '--word-regexp'],  's': ['>', 'w'] },
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#rg#cmd(esearch, pattern, escape) abort
  let options = esearch#adapter#rg#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return g:esearch#adapter#rg#bin.' '.r.' '.c.' '.w.' --no-heading --color=never --line-number -H ' .
        \ g:esearch#adapter#rg#options . ' -- ' .
        \ a:escape(a:pattern)  . ' ' . joined_paths
endfu

fu! esearch#adapter#rg#requires_pty() abort
  return 1
endfu

fu! esearch#adapter#rg#is_success(request) abort
  " https://github.com/BurntSushi/ripgrep/issues/948
  return a:request.status == 0
        \ || (a:request.status == 1 && empty(a:request.errors) && empty(a:request.data))
endfu
