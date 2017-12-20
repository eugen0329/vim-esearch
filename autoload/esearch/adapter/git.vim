if !exists('g:esearch#adapter#git#options')
  let g:esearch#adapter#git#options = ''
endif

let s:format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

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

fu! esearch#adapter#git#cmd(pattern, dir, escape, ...) abort
  let options = a:0 ? a:1 : esearch#adapter#git#_options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  " -H - don't show filenames
  " -I - don't search binary files
  return 'git --no-pager grep '.r.' '.c.' '.w.' -H -I --no-color --line-number ' .
        \ g:esearch#adapter#git#options . ' -- ' .
        \ a:escape(a:pattern)  . ' ' . fnameescape(a:dir)
endfu

fu! esearch#adapter#git#is_broken_result(line) abort
  return empty(matchlist(a:line, s:format)[1:3])
endfu

fu! esearch#adapter#git#parse_results(raw, from, to, broken_results, pattern) abort
  if empty(a:raw) | return [] | endif
  let format = s:format
  let results = []
  let pattern = a:pattern

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let el = matchlist(a:raw[i], format)[1:3]
    if empty(el)
      if index(a:broken_results, a:raw[i]) < 0
        call add(a:broken_results, a:raw[i])
      endif
    else
      let col = match(el[2], pattern) + 1
      if !col | let col = 1 | endif
      call add(results, {'filename': el[0], 'lnum': el[1], 'col': col, 'text': el[2]})
    endif
    let i += 1
  endwhile
  return results
endfu

fu! esearch#adapter#git#requires_pty() abort
  return 1
endfu

" Used to build the query
fu! s:parametrize(key, ...) dict abort
  let option_index = g:esearch[a:key]
  return self[a:key]['p'][option_index]
endfu
