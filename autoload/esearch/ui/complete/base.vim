fu! esearch#ui#complete#base#word_and_prefix(arglead) abort
  let leading_words = split(a:arglead, '\s\+')
  " no current word
  if a:arglead =~# '\s$' || empty(leading_words)
    return ['' , a:arglead]
  endif

  let word = leading_words[-1]
  if strchars(a:arglead) == strchars(word)
    return [word, '']
  endif

  return [word, a:arglead[: strchars(a:arglead) - strchars(word) - 1]]
endfu

fu! esearch#ui#complete#base#prepare(candidates, cmdline, prefix) abort
  return map(filter(a:candidates, 'stridx(a:cmdline, v:val) == -1'), 'a:prefix . v:val')
endfu
