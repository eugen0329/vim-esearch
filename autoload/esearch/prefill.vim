fu! esearch#prefill#try(esearch) abort
  for prefiller in a:esearch.prefill
    let pattern = esearch#prefill#{prefiller}(a:esearch)
    if !empty(pattern) | return pattern | endif
  endfor

  return {'literal': '', 'pcre': ''}
endfu


fu! esearch#prefill#region(esearch) abort
  if !empty(get(a:esearch, 'region'))
    let text = call('esearch#util#region_text', a:esearch.region)
    return {'pcre': text, 'literal': text}
  endif
endfu

fu! esearch#prefill#visual(esearch) abort
  " DEPRECATED
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

fu! esearch#prefill#clipboard(esearch) abort
  return {'literal': getreg('"'), 'pcre': getreg('"')}
endfu

fu! esearch#prefill#system_clipboard(esearch) abort
  return {'literal': getreg('+'), 'pcre': getreg('+')}
endfu

fu! esearch#prefill#unnamed_register(esearch) abort
  return {'literal': @@, 'pcre': @@}
endfu

fu! esearch#prefill#system_selection_clipboard(esearch) abort
  return {'literal': getreg('+'), 'pcre': getreg('+')}
endfu
