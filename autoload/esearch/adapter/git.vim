if !exists('g:esearch#adapter#git#options')
  let g:esearch#adapter#git#options = ''
endif
if !exists('g:esearch#adapter#git#bin')
  let g:esearch#adapter#git#bin = 'git'
endif

fu! esearch#adapter#git#_options() abort
  if !exists('s:options')
    if has('macunix')
      let regex = '-E'
    else
      let regex = '--perl-regexp'
    endif
    let s:options = {
    \ 'regex': { 'p': ['--fixed-strings', regex], 's': ['>', 'r'] },
    \ 'case':  { 'p': ['--ignore-case',   ''             ], 's': ['>', 'c'] },
    \ 'word':  { 'p': ['',                '--word-regexp'], 's': ['>', 'w'] },
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#git#cmd(esearch, pattern, escape) abort
  let options = esearch#adapter#git#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  " -H - show filenames
  " -I - don't search binary files

  let joined_paths = esearch#adapter#grep_like#joined_paths(a:esearch)

  return g:esearch#adapter#git#bin.' -C '.fnameescape(a:esearch.cwd) .
        \ ' --no-pager grep '.r.' '.c.' '.w.' -H -I --no-color --line-number ' .
        \ g:esearch#adapter#git#options . ' -- ' .
        \ a:escape(a:pattern) . ' ' . joined_paths
endfu

fu! esearch#adapter#git#set_results_parser(esearch) abort
  let a:esearch.parse = function('esearch#adapter#grep_like#parse')
  let a:esearch.format = g:esearch#adapter#grep_like#multiple_files_Search_format
  let a:esearch.expand_filename = function('<SID>expand_filename')
endfu

fu! s:expand_filename(filename) abort dict
  let filename = a:filename
  if filename[0] ==# '"' && filename[strchars(filename)-1] ==# '"'
    return filename[0 : strchars(filename)-1]
  endif

  return filename
endfu

fu! esearch#adapter#git#requires_pty() abort
  return 1
endfu
