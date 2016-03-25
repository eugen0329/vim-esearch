fu! esearch#source#pick_exp(use, opts)
  let use = type(a:use) == type('') ? [a:use] : a:use

  for name in use
    let exp = esearch#source#{name}(a:opts)
    if !empty(exp) | return exp | endif
    unlet exp
  endfor

  return esearch#regex#new()
endfu

fu! esearch#source#visual(opts)
  if get(a:opts, 'visualmode', 0)
    let visual = esearch#util#visual_selection()
    return esearch#regex#new({'vim': visual, 'pcre': visual, 'literal': visual})
  else
    return 0
  endif
endfu

fu! esearch#source#hlsearch(...)
  if get(v:, 'hlsearch', 0)
    let vexp = getreg('/')
    return esearch#regex#new({
          \  'vim': vexp,
          \  'pcre': esearch#regex#vim2pcre(vexp),
          \  'literal': esearch#regex#vim_sanitize(vexp)
          \ })
  else
    return 0
  endif
endfu

fu! esearch#source#last(...)
  if exists('g:esearch')
    return get(g:esearch, '_last_exp', 0)
  else
    return 0
  endif
endfu

fu! esearch#source#filename(...)
  let w = expand('%')
endfu

fu! esearch#source#cword(...)
  let w = expand('<cword>')
  return esearch#regex#new({'vim': w, 'pcre': w, 'literal': w})
endfu
fu! esearch#source#word_under_cursor(...)
  return call('esearch#source#cword', a:000)
endfu
