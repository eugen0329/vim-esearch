fu! esearch#ui#complete#base#parse_arglead(arglead) abort
  let leading_words = split(a:arglead, '\s\+')
  if a:arglead =~# '\s$' || empty(leading_words)
    return ['' , a:arglead]
  endif

  let current_word = leading_words[-1]
  if strchars(a:arglead) == strchars(current_word)
    return [current_word, '']
  endif

  let prefix_text = a:arglead[: strchars(a:arglead) - strchars(current_word) - 1]
  if prefix_text !~# '\s$'
    let prefix_text .= ' '
  endif

  return [current_word, prefix_text]
endfu
