fu! esearch#converters#vim2pcre(exp)
  let exp = a:exp
  " let exp = substitute(exp, '[^\]\?\zs\\([+{]\)', '\1', 'g')
  let exp = substitute(exp, '\\\([+{]\)', '\1', 'g')

  " word boundary
  " let exp = substitute(exp, '[^]\?\zs\\[<>]', '', 'g')
  let exp = substitute(exp, '\\[<>]', '\\b', 'g')

  " grouping
  let exp = substitute(exp, '\\%(', '(', 'g')
  let exp = substitute(exp, '\\)', ')', 'g')

  let exp = substitute(exp, '\\%\d\+[vlc]', '', 'g')

  return exp
endfu
