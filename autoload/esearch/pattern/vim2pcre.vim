fu! esearch#pattern#vim2pcre#convert(string) abort
  let string = a:string
  " From :h pattern-atoms
  let string = substitute(string, '\\_\([$.^]\)',       '\\1', 'g')
  let string = substitute(string, '\\[<>]',             '\\b', 'g')
  let string = substitute(string, '\\z[se]',            '',    'g')
  let string = substitute(string, '\\%\([$^]\)',        '\1',  'g')
  let string = substitute(string, '\\%[V#]',            '',    'g')
  " marks matches
  let string = substitute(string, '\\%[<>]\=''\w',      '',    'g')
  " line/column matches
  let string = substitute(string, '\\%[<>]\=\d\+[vlc]', '',    'g')
  " (no)magic, very (no)magic and case sensitiveness
  let string = substitute(string, '\\[mMvVcC]',         '',    'g')

  return string
endfu
