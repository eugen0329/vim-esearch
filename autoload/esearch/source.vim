fu! esearch#source#pick_exp(use, esearch) abort
  let use = type(a:use) == type('') ? [a:use] : a:use

  for name in use
    let pattern = esearch#source#{name}(a:esearch)
    if !empty(pattern) | return pattern | endif
  endfor

  return {'literal': '', 'pcre': ''}
endfu

fu! esearch#source#visual(esearch) abort
  if get(a:esearch, 'visualmode', 0)
    let visual = esearch#util#visual_selection()
    return {'pcre': visual, 'literal': visual}
  endif
endfu

fu! esearch#source#hlsearch(esearch) abort
  if !get(v:, 'hlsearch', 0) | return | endif

  let str = getreg('/')
  if empty(str) | return | endif

  return {
        \  'pcre':    esearch#pattern#vim2pcre#convert(str),
        \  'literal': esearch#pattern#vim2literal#convert(str)
        \ }
endfu

fu! esearch#source#last(esearch) abort
  return get(g:esearch, 'last_pattern', 0)
endfu

fu! esearch#source#current(esearch) abort
  if exists('b:esearch') | return get(b:esearch, 'pattern', 0) | endif
endfu

fu! esearch#source#cword(esearch) abort
  return {'literal': expand('<cword>'), 'pcre': expand('<cword>')}
endfu
fu! esearch#source#word_under_cursor(esearch) abort
  return {'literal': expand('<cword>'), 'pcre': expand('<cword>')}
endfu

fu! esearch#source#clipboard() abort
  return {'literal': getreg('"'), 'pcre': getreg('"')}
endfu

fu! esearch#source#system_clipboard() abort
  return {'literal': getreg('+'), 'pcre': getreg('+')}
endfu
fu! esearch#source#system_selection_clipboard() abort
  return {'literal': getreg('+'), 'pcre': getreg('+')}
endfu
