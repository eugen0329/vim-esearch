let s:window_id  = esearch#util#counter()
let s:UNDEFINED = esearch#polyfill#undefined()

fu! esearch#win#bulk_let(handle, variables) abort
  for [name, l:Val] in items(a:variables)
    if Val is s:UNDEFINED | continue | endif
    call esearch#win#let(a:handle, name, Val)
  endfor
endfu

fu! esearch#win#let_restorable(handle, variables) abort
  return esearch#let#restorable(
        \ a:variables,
        \ s:Guard.new(a:handle),
        \ function('esearch#win#bulk_let', [a:handle]))
endfu

fu! esearch#win#let(winid, name, value) abort
  call settabwinvar(win_id2tabwin(a:winid)[0], a:winid, a:name[(a:name =~# '^w:' ? 2 : 0):], a:value)
endfu

fu! esearch#win#get(winid, name) abort
  return gettabwinvar(win_id2tabwin(a:winid)[0], a:winid, a:name[(a:name =~# '^w:' ? 2 : 0):], s:UNDEFINED)
endfu

fu! esearch#win#stay() abort
  return s:CurrentWindowGuard.new()
endfu

fu! esearch#win#guard() abort
  return s:Guard
endfu

let s:Guard = {}

fu! s:Guard.new(handle) abort dict
  let instance = copy(self)
  let instance.winid = a:handle
  let instance._resources = {}
  return instance
endfu

fu! s:Guard.store(targets) abort dict
  for name in a:targets
    let self._resources[name] = esearch#win#get(self.winid, name)
  endfor

  return self
endfu

fu! s:Guard.restore() abort dict
  if esearch#win#exists(self.winid)
    call esearch#win#bulk_let(self.winid, self._resources)
  endif
endfu

let s:CurrentWindowGuard = {}

" Python-like context manager to restore current window with following vital's guards
" interface

fu! s:CurrentWindowGuard.new() abort dict
  let instance = copy(self)
  let instance.view = winsaveview()
  let instance.winid = win_getid()
  return instance
endfu

fu! s:CurrentWindowGuard.restore() abort dict
  call win_gotoid(self.winid)
  call winrestview(self.view)
endfu

fu! esearch#win#lcd(path) abort
  return s:DirectoryGuard.store(a:path)
endfu

let s:DirectoryGuard = {'cwd': ''}

fu! s:DirectoryGuard.store(path) abort dict
  let instance = copy(self)

  if !empty(a:path)
    let instance.cwd = getcwd()
    exe 'lcd ' . a:path
  endif

  return instance
endfu

fu! s:DirectoryGuard.restore() abort dict
  if !empty(self.cwd)
    exe 'lcd ' . self.cwd
  endif
endfu

fu! esearch#win#exists(handle) abort
  return winbufnr(a:handle) != -1
endfu
