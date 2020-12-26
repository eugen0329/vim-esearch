let s:Dict      = vital#esearch#import('Data.Dict')
let s:Guard     = vital#esearch#import('Vim.Guard')
let s:UNDEFINED = esearch#polyfill#undefined()

let s:scope2id = {'g': 0, 'b': 0, 'w': 1}
let s:opt2id = map(split(g:esearch#options#scopes), 'split(v:val, ":")')
let s:opt2id = s:Dict.from_list(map(s:opt2id, '["&".v:val[1], s:scope2id[v:val[0]]]'))

fu! esearch#let#bufwin_restorable(bufnr, winid, variables) abort
  return s:BufWinGuard.new(a:bufnr, a:winid).store(a:variables)
endfu

let s:BufWinGuard = {}

fu! s:BufWinGuard.new(bufnr, winid) abort dict
  return extend(copy(self), {
        \ 'getters': [function('esearch#buf#get', [a:bufnr]), function('esearch#win#get', [a:winid])],
        \ 'setters': [function('esearch#buf#let', [a:bufnr]), function('esearch#win#let', [a:winid])],
        \ 'bufnr': a:bufnr, 'winid': a:winid})
endfu

fu! s:BufWinGuard.store(variables) abort
  let self._resources = [[], []]

  for [name, l:Val] in items(a:variables)
    if has_key(s:opt2id, name)
      let id = s:opt2id[name]
      call add(self._resources[id], [name, self.getters[id](name)])
      call self.setters[id](name, Val)
    else
      let id = s:scope2id[name[0]]
      call add(self._resources[id], [name, self.getters[id](name)])
      call self.setters[id](name, Val)
    endif
  endfor

  return self
endfu

fu! s:BufWinGuard.restore() abort dict
  for [name, l:Val] in self._resources[0]
    if Val is s:UNDEFINED | continue | endif
    call self.setters[0](name, Val)
  endfor
  if esearch#win#exists(self.winid)
    for [name, l:Val] in self._resources[1]
      if Val is s:UNDEFINED | continue | endif
      call self.setters[1](name, Val)
    endfor
  endif
endfu

" Generic letter (not setter, to not confuse with set command). Behaves like a
" usual let
" Most parts are inspired by Vim.Guard source code
fu! esearch#let#bulk(variables) abort
  for [name, value] in items(a:variables)
    if name =~# '^[bwtg]:'
      exe printf('let %s = %s', name, type(value) ==# type('') ? string(value) : value)
    elseif name =~# '^&'
      exe printf('let %s = %s', name, string(value))
    elseif name =~# '^@'
      call s:set_reg(name, value)
    elseif name =~# '^\$'
      exe printf('let %s = %s', name, string(value))
    else
      throw printf('Unknown value "%s" was specified', name)
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

" Python-like context manager to temporary set variables with following vital's guards
" interface
fu! esearch#let#restorable(variables, ...) abort
  let l:Guard  = get(a:, 1, s:Guard)
  let l:Setter = get(a:, 2, function('esearch#let#bulk'))

  let guard = Guard.store(keys(a:variables))
  try
    call Setter(a:variables)
  catch
    call guard.restore()
    throw 'Let:' . v:exception
  endtry

  return guard
endfu
