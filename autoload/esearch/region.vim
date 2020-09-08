fu! esearch#region#exec(type, key) abort
  if esearch#util#is_visual(a:type)
    silent exe 'normal! gv'.a:key
  elseif a:type ==# 'line'
    silent exe "normal! '[V']".a:key
  else
    silent exe 'normal! `[v`]'.a:key
  endif
endfu

fu! esearch#region#pos(type) abort
  let options = esearch#let#restorable({'@@': '', '&selection': 'inclusive'})
  try
    call esearch#region#exec(a:type, "\<esc>")
    return [getpos("'<")[1:2], getpos("'>")[1:2]]
  finally
    call options.restore()
  endtry
endfu

fu! esearch#region#text(type) abort
  let options = esearch#let#restorable({'@@': '', '&selection': 'inclusive'})
  try
    call esearch#region#exec(a:type, 'y')
    return @@
  finally
    call options.restore()
  endtry
endfu
