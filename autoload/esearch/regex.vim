fu! esearch#regex#new(visual, opts)
  if a:visual && a:opts.use.visual
    let vexp = esearch#util#visual_selection()
    return { 'vim': vexp, 'pcre': vexp, 'literal': vexp }
  elseif get(v:, 'hlsearch', 0) && a:opts.use.hlsearch
    let vexp = getreg('/')
    return { 'vim': vexp,
          \  'pcre': esearch#regex#vim2pcre(vexp),
          \  'literal': esearch#regex#vim_sanitize(vexp)
          \ }
  else
    return { 'vim': '', 'pcre': '', 'literal': '' }
  endif
endfu

fu! esearch#regex#finalize(exp, opts)
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

fu! esearch#regex#vim2pcre(exp)
  let exp = a:exp

  let exp = substitute(exp, '\\\([+{]\)', '\1', 'g')

  " word boundary
  let exp = substitute(exp, '\\[<>]', '\\b', 'g')

  " grouping
  let exp = substitute(exp, '\\%(', '(', 'g')
  let exp = substitute(exp, '\\)', ')', 'g')

  let exp = substitute(exp, '\\%\d\+[vlc]', '', 'g')

  return exp
endfu

fu! esearch#regex#vim_sanitize(exp)
  let exp = a:exp

  let exp = substitute(exp, '\\\([+{()<>]\)', '', 'g')
  let exp = substitute(exp, '\\%', '%', 'g')


  return exp
endfu

fu! esearch#regex#pcre_sanitize(exp)
  let exp = a:exp

  let exp = substitute(exp, '\\\([b]\)', '', 'g')

  return exp
endfu

fu! esearch#regex#pcre2vim(exp)
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
