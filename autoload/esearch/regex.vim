" GLOBAL TODO
fu! esearch#regex#build(use, visual_mode)
  for source in a:use
    let exp = s:{source}_exp(a:visual_mode)
    if !empty(exp) | return exp | endif
    unlet exp
  endfor
  return esearch#regex#new()
endfu

fu! esearch#regex#new(...) abort
  let blank = { 'vim': '', 'pcre': '', 'literal': '' }
  if a:0
    return extend(a:1, blank, 'keep')
  else
    return blank
  endif
endfu

fu! esearch#regex#finalize(exp, opts) abort
  let vexp = a:exp.vim
  let vexp = escape(vexp, '$')
  if a:opts.word
    let vexp = '\%(\<\|\>\)'.vexp.'\%(\<\|\>\)'
  endif
  if !a:opts.case
    let vexp = '\c'.vexp
  endif
  let vexp = '\%>2l\%(\s\+\d\+.*\)\@<='.vexp
  return extend(a:exp, { 'vim_match': vexp })
endfu

fu! esearch#regex#vim2pcre(exp) abort
  let exp = a:exp

  let exp = substitute(exp, '\\\([+{]\)', '\1', 'g')

  " word boundary
  let exp = substitute(exp, '\\[<>]', '\\b', 'g')

  " Remove \v \V (very magic)
  let exp = substitute(exp, '\\[vV]', '', 'g')

  " grouping
  let exp = substitute(exp, '\\%(', '(', 'g')
  let exp = substitute(exp, '\\)', ')', 'g')

  let exp = substitute(exp, '\\%\d\+[vlc]', '', 'g')

  return exp
endfu

fu! esearch#regex#vim_sanitize(exp) abort
  let exp = a:exp

  let exp = substitute(exp, '\\\([+{()<>]\)', '', 'g')
  let exp = substitute(exp, '\\%', '%', 'g')

  " Remove \v \V (very magic)
  let exp = substitute(exp, '\\[vV]', '', 'g')


  return exp
endfu

fu! esearch#regex#pcre_sanitize(exp) abort
  let exp = a:exp

  let exp = substitute(exp, '\\\([b]\)', '', 'g')

  return exp
endfu

fu! esearch#regex#pcre2vim(exp) abort
  let exp = a:exp
  " let exp = substitute(exp, '[^\]\?\zs\\([+{]\)', '\1', 'g')
  let exp = substitute(exp, '\([+{]\)', '\\\1', 'g')

  " word boundary
  " let exp = substitute(exp, '[^]\?\zs\\[<>]', '', 'g')
  " let exp = substitute(exp, '\\[<>]', '\\b', 'g')

  " " grouping
  " let exp = substitute(exp, '\\%(', '(', 'g')
  " let exp = substitute(exp, '\\)', ')', 'g')

  " let exp = substitute(exp, '\\%\d\+[vlc]', '', 'g')

  return exp
endfu

fu! s:visual_exp(visual_mode)
  if a:visual_mode
    let visual = esearch#util#visual_selection()
    return esearch#regex#new({'vim': visual, 'pcre': visual, 'literal': visual})
  else
    return 0
  endif
endfu

fu! s:hlsearch_exp(...)
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
