fu! esearch#inflector#pluralize(word, count)
  if a:count % 10 == 1
    return a:word
  endif

  return s:plurlize(a:word)
endfu

" tim pope
fu! s:plurlize(word)
  let word = a:word

  if empty(word)
    return word
  endif

  let word = s:sub(word,'[aeio]@<!y$','ie')
  let word = s:sub(word,'%(nd|rt)@<=ex$','ice')
  let word = s:sub(word,'%([sxz]|[cs]h)$','&e')
  let word = s:sub(word,'f@<!f$','ve')
  let word .= 's'
  return word
endfu

fu! s:sub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfu
