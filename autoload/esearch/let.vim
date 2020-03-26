let s:Guard = vital#esearch#import('Vim.Guard')
let s:GenericLet = function('esearch#let#generic')

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

" Generic letter (not setter, to not confuse with set command). Behaves like a
" usual let
fu! esearch#let#generic(variables) abort
  " Most parts are inspired by Vim.Guard source code
  for [name, value] in items(a:variables)
    if name =~# '^[bwtg]:'
      call s:let_var(name, value)
    elseif name =~# '^&'
      exe printf('let %s = %s', name, string(value))
    elseif name =~# '^@'
      call s:set_reg(name, value)
    elseif name =~# '^\$'
      exe printf('let %s = %s', name, string(value))
    else
      throw printf(
            \ 'Unknown value "%s" was specified',
            \ name
            \)
    endif
  endfor
endfu

fu! s:set_reg(name, value) abort
  " https://github.com/vim/vim/commit/5a50c2255c447838d08d3b4895a3be3a41cd8eda
  if has('patch-7.4.243') || a:name[1] !=# '='
    call setreg(a:name[1], a:value)
  else
    let @= = a:value
  endif
endfu

fu! s:let_var(name, value) abort
  exe printf('let %s = %s', a:name,
        \ type(a:value) ==# type('') ? string(a:value) : a:value)
endfu

" Python-like context manager to temporary set variables with following vital's guards
" interface

fu! esearch#let#restorable(variables, ...) abort
  let Guard  = get(a:000, 0, s:Guard)
  let Letter = get(a:000, 1, s:GenericLet)

  let guard = Guard.store(keys(a:variables))
  try
    call Letter(a:variables)
  catch
    call guard.restore()
    throw v:exception
  endtry

  return guard
endfu
