fu! esearch#prefill#try(esearch) abort
  for prefiller in a:esearch.prefill
    let pattern = esearch#prefill#{prefiller}(a:esearch)
    if !empty(pattern) | return pattern | endif
  endfor

  return {'literal': '', 'pcre': ''}
endfu

fu! esearch#prefill#visual(esearch) abort
  if get(a:esearch, 'visualmode', 0)
    let visual = esearch#util#visual_selection()
    return {'pcre': visual, 'literal': visual}
  endif
endfu

fu! esearch#prefill#hlsearch(esearch) abort
  if !get(v:, 'hlsearch', 0) | return | endif

  let str = getreg('/')
  if empty(str) | return | endif

  return {
        \  'pcre':    esearch#pattern#vim2pcre#convert(str),
        \  'literal': esearch#pattern#vim2literal#convert(str)
        \ }
endfu

fu! esearch#prefill#last(esearch) abort
  return get(g:esearch, 'last_pattern', 0)
endfu

fu! esearch#prefill#current(esearch) abort
  if exists('b:esearch') | return get(b:esearch, 'pattern', 0) | endif
endfu

fu! esearch#prefill#cword(esearch) abort
  return {'literal': expand('<cword>'), 'pcre': expand('<cword>')}
endfu

fu! esearch#prefill#word_under_cursor(esearch) abort
  return {'literal': expand('<cword>'), 'pcre': expand('<cword>')}
endfu

fu! esearch#prefill#clipboard() abort
  return {'literal': getreg('"'), 'pcre': getreg('"')}
endfu

fu! esearch#prefill#system_clipboard() abort
  return {'literal': getreg('+'), 'pcre': getreg('+')}
endfu

fu! esearch#prefill#system_selection_clipboard() abort
  return {'literal': getreg('+'), 'pcre': getreg('+')}
endfu
