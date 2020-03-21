let s:Guard = vital#esearch#import('Vim.Guard')
let s:null = 0

" Python-like approach to set variables per context

fu! esearch#context_manager#let#new() abort
  return s:Let.new()
endfu

let s:Let = {'guard': s:null}

fu! s:Let.new() abort
  return copy(self)
endfu

" Most parts are inspired by Vim.Guard source code
fu! s:Let.enter(variables) abort dict
  if empty(a:variables) | return self | endif

  let self.guard = s:Guard.store(keys(a:variables))

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
  return self
endfu

fu! s:Let.exit() abort dict
  if empty(self.guard) | return self | endif
  call self.guard.restore()
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
