let s:esc = g:esearch#util#even_count_of_escapes_re . '\zs'

fu! esearch#pattern#vim2literal#convert(string) abort
  let string = a:string
  " :h pattern-atoms
  let string = substitute(string, s:esc . '\\_\([$.^]\)',       '',    'g')
  let string = substitute(string, s:esc . '\\[<>]',             '',    'g')
  let string = substitute(string, s:esc . '\\z[se]',            '',    'g')
  let string = substitute(string, s:esc . '\\%\([$^]\)',        '',    'g')
  let string = substitute(string, s:esc . '\\%[V#]',            '',    'g')
  " marks matches
  let string = substitute(string, s:esc . '\\%[<>]\=''\w',      '',    'g')
  " line/column matches
  let string = substitute(string, s:esc . '\\%[<>]\=\d\+[vlc]', '',    'g')
  " (no)magic, very (no)magic and case sensitiveness
  let string = substitute(string, s:esc . '\\[mMvVcC]',         '',    'g')
  " unescape /
  let string = substitute(string, s:esc . '\\/',                '/',   'g')

  return string
endfu
