let s:format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

fu! esearch#adapter#grep#options() abort
  if !exists('s:options')
    " -P: pcre
    let s:options = {
    \ 'regex':   { 'p': ['', '-P'],   's': ['>', 'r'] },
    \ 'case':    { 'p': ['-i', ''],   's': ['>', 'c'] },
    \ 'word':    { 'p': ['',   '-w'], 's': ['>', 'w'] },
    \ 'stringify':   function('esearch#util#stringify'),
    \ 'parametrize': function('esearch#util#parametrize'),
    \}
  endif
  return s:options
endfu

fu! esearch#adapter#grep#cmd(pattern, dir, escape, ...) abort
  let options = a:0 ? a:1 : esearch#adapter#grep#options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  " -r: no follow symbolic links
  " -I: Process a binary file as if it did not contain matching data
  return "grep ".r." ".c." ".w." -r -n --exclude-dir=.{git,svn,hg} -- " .
        \ a:escape(a:pattern)  . " " . a:escape(a:dir)
endfu

fu! esearch#adapter#grep#is_broken_result(line)
  return empty(matchlist(a:line, s:format)[1:3])
endfu

fu! esearch#adapter#grep#parse_results(raw, from, to, broken_results, pattern) abort
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
      call add(results, {'fname': el[0], 'lnum': el[1], 'col': col, 'text': el[2]})
    endif
    let i += 1
  endwhile
  return results
endfu

fu! esearch#adapter#grep#requires_pty()
  return 1
endfu

" Used to build the query
fu! s:parametrize(key, ...) dict abort
  let option_index = g:esearch[a:key]
  return self[a:key]['p'][option_index]
endfu
