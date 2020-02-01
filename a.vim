
let re_unescaped='\%(\\\)\@<!\%(\\\\\)*\zs'
let escaped='\%(\\\)\@<!\%(\\\\\)*\zs\\'

let re_unescaped='\%(\\\)\@<!\%(\\\\\)*\zs'
let escaped='\%(\\\)\@<!\%(\\\\\)*\\'

let string = 'a b\ c "d e" ''e f'''
let string = 'a b\ \ c "d e" ''e f'''
" let string = 'a b\ c "d e" ''e f'


let e = 0

let untermianted = []

let single_quoted = '''\([^'']\+\)'''
let double_quoted = '"\([^"]\+\)"'
let with_escaped_spaces = '\([^\\ ]\|'.escaped.' \)\+'
let non_space = '\([^ ]\+\)'
let re = join([single_quoted, double_quoted, with_escaped_spaces, non_space], '\|')
while 1
  " let re = '\([^\\ ]\|'.escaped.' \)\+'

  if match(string, re, e) < 0
    break
  endif

  let m = matchstr(string, re, e)
  if m =~ escaped. ' '
    echo [e, matchend(string, re, e), substitute(m, '\\\s', ' ', 'g')]
  elseif m[0] =~ '["'']' && m[0] != m[len(m)-1]
    echo 'unterminated'
    call add(untermianted, m)
    echo [e, matchend(string, re, e), m]
  elseif m[0] =~ '["'']'
    echo [e, matchend(string, re, e), m[1:len(m)-2]]
  else
    echo [e, matchend(string, re, e), m]
  endif
  let e = matchend(string, re, e)
endwhile
