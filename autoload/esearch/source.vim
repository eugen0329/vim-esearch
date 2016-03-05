fu! esearch#source#visual(visual_mode)
  if a:visual_mode
    let visual = esearch#util#visual_selection()
    return esearch#regex#new({'vim': visual, 'pcre': visual, 'literal': visual})
  else
    return 0
  endif
endfu

fu! esearch#source#hlsearch(...)
  if get(v:, 'hlsearch', 0)
    let vexp = getreg('/')
    return esearch#regex#new({ 'vim': vexp,
          \  'pcre': esearch#regex#vim2pcre(vexp),
          \  'literal': esearch#regex#vim_sanitize(vexp)
          \ })
  else
    return 0
  endif
endfu
