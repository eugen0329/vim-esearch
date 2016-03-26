let s:format = '^\(.\{-}\)\:\(\d\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

fu! esearch#adapter#ag#options() abort
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

fu! esearch#adapter#ag#cmd(pattern, dir, escape, ...) abort
  let options = a:0 ? a:1 : esearch#adapter#ag#options()
  let r = options.parametrize('regex')
  let c = options.parametrize('case')
  let w = options.parametrize('word')
  return "ag ".r." ".c." ".w." --nogroup --nocolor --column -- " .
        \ a:escape(a:pattern)  . " " . a:escape(a:dir)
endfu

fu! esearch#adapter#ag#is_broken_result(line)
  return empty(matchlist(a:line, s:format)[1:4])
endfu

fu! esearch#adapter#ag#requires_pty()
  return 1
endfu

fu! esearch#adapter#ag#parse_results(raw, from, to, broken_results, ...) abort
  if empty(a:raw) | return [] | endif
  let format = s:format
  let results = []

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let el = matchlist(a:raw[i], format)[1:4]
    if empty(el)
      if index(a:broken_results, a:raw[i]) < 0
        call add(a:broken_results, a:raw[i])
      endif
    else
      call add(results, {'fname': el[0], 'lnum': el[1], 'col': el[2], 'text': el[3]})
    endif
    let i += 1
  endwhile
  return results
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

function! esearch#adapter#ag#sid()
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
