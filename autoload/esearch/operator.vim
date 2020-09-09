fu! esearch#operator#cmd(wise, seq, reg) abort
  let seq = (empty(a:reg) ? '' : '"'.a:reg) . a:seq
  if esearch#util#is_visual(a:wise)
    return 'normal! gv' . seq
  elseif a:wise ==# 'line'
    return "normal! '[V']" . seq
  else
    return 'normal! `[v`]' . seq
  endif
endfu

fu! esearch#operator#text(wise) abort
  let options = esearch#let#restorable({'&selection': 'inclusive'})
  try
    exe esearch#operator#cmd(a:wise, 'y', '')
    return @@
  finally
    call options.restore()
  endtry
endfu

fu! esearch#operator#expr(operatorfunc) abort
  if mode(1)[:1] ==# 'no'
    return 'g@'
  elseif mode() ==# 'n'
    let [s:count, s:reg, &operatorfunc] = [v:count, v:register, a:operatorfunc]
    return (s:count ? s:count : '').(empty(s:reg) ? '' : '"'.s:reg).'g@'
  else
    let [s:count, s:reg] = [v:count, v:reg]
    return ":\<c-u>call ".a:operatorfunc."(visualmode())\<cr>"
  endif
endfu

fu! esearch#operator#is_linewise(wise) abort
  return a:wise ==# 'V' || a:wise ==# 'line'
endfu

fu! esearch#operator#is_charwise(wise) abort
  return a:wise ==# 'v' || a:wise ==# 'char'
endfu

fu! esearch#operator#vars() abort
  return [s:count, s:reg]
endfu
