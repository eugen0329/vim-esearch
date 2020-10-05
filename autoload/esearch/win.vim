let s:window_id  = esearch#util#counter()
let s:UNDEFINED = esearch#polyfill#undefined()

" Utility functions to work with windows. Includes:
" - normalized windows api
" - guards to set/reset windows configs without enter

fu! esearch#win#guard() abort
  return s:Guard
endfu

let s:Guard = {}

fu! s:Guard.new(handle) abort dict
  let instance = copy(self)
  let instance.handle = a:handle
  let instance._resources = {}
  return instance
endfu

"""""""""""""""""""""""""""""""""""""""

fu! esearch#win#stay() abort
  return s:CurrentWindowGuard.new()
endfu

let s:CurrentWindowGuard = {}

" Python-like context manager to restore current window with following vital's guards
" interface

fu! s:CurrentWindowGuard.new() abort dict
  let instance = copy(self)
  let instance.view = winsaveview()
  let instance.handle = esearch#win#trace()
  return instance
endfu

fu! s:CurrentWindowGuard.restore() abort dict
  call esearch#win#goto(self.handle)
  call winrestview(self.view)
endfu

"""""""""""""""""""""""""""""""""""""""

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

"""""""""""""""""""""""""""""""""""""""

fu! esearch#win#let_restorable(handle, variables) abort
  return esearch#let#restorable(
        \ a:variables,
        \ s:Guard.new(a:handle),
        \ function('esearch#win#bulk_let', [a:handle]))
endfu

"""""""""""""""""""""""""""""""""""""""

if g:esearch#has#nvim_winid
  " Neovim methods are used instead of cross-editor win_gotoid() etc. to allow
  " working with non-focusable neovim floating windows.

  fu! esearch#win#exists(handle) abort
    return nvim_win_is_valid(a:handle)
  endfu

  fu! esearch#win#trace(...) abort
    if a:0
      return win_getid(a:2, a:1)
    else
      return nvim_get_current_win()
    endif
  endfu

  fu! esearch#win#goto(handle) abort
    return nvim_set_current_win(a:handle)
  endfu

  fu! esearch#win#bufnr(handle) abort
    return nvim_win_get_buf(a:handle)
  endfu

  fu! esearch#win#id(handle) abort
    return a:handle
  endfu

  fu! esearch#win#let(handle, name, value) abort
    if a:name =~# '^w:'
      call nvim_win_set_var(a:handle, a:name[2:], a:value)
    else
      call nvim_win_set_option(a:handle, a:name[1:], a:value)
    endif
  endfu

  fu! esearch#win#bulk_let(handle, variables) abort
    for [name, value] in items(a:variables)
      call esearch#win#let(a:handle, name, value)
    endfor
  endfu

  fu! esearch#win#get(handle, name) abort
    try
      if a:name =~# '^w:'
        return nvim_win_get_var(a:handle, a:name[2:])
      else
        return nvim_win_get_option(a:handle, a:name[1:])
      endif
    catch /E5555:/
      return s:UNDEFINED
    endtry
  endfu

  fu! esearch#win#find(id) abort
    return [a:id]
  endfu

  " implements Vital api
  fu! s:Guard.store(targets) abort dict
    for name in a:targets
      if name =~# '^w:'
        let value = nvim_win_get_var(self.handle, name[2:])
      else
        " echomsg self.handle
        let value = nvim_win_get_option(self.handle, name[1:])
      endif

      let self._resources[name] = value
    endfor

    return self
  endfu
else
  let s:ViewTracer = vital#esearch#import('Vim.ViewTracer')

  fu! esearch#win#exists(handle) abort
    return s:ViewTracer.exists(a:handle)
  endfu

  fu! esearch#win#trace(...) abort
    let [tabnr, winnr] = a:0 ? a:000 : [tabpagenr(), winnr()]
    call settabwinvar(tabnr, winnr, 'esearch', s:window_id.next())
    return s:ViewTracer.trace_window(tabnr, winnr)
  endfu

  fu! esearch#win#goto(handle) abort
    call s:ViewTracer.jump(a:handle)
  endfu

  fu! esearch#win#id(handle) abort
    return call('win_getid', reverse(s:ViewTracer.find(a:handle)))
  endfu

  fu! esearch#win#bufnr(handle) abort
    let [tabnr, winnr] = s:ViewTracer.find(a:handle)
    let buflist = tabpagebuflist(tabnr)
    return buflist[winnr - 1]
  endfu

  fu! esearch#win#let(tabnr, winnr, name, value) abort
    call settabwinvar(a:tabnr, a:winnr, a:name[(a:name =~# '^w:' ? 2 : 0):], a:value)
  endfu

  fu! esearch#win#bulk_let(handle, variables) abort
    let [tabnr, winnr] = s:ViewTracer.find(a:handle)
    for [name, value] in items(a:variables)
      call esearch#win#let(tabnr, winnr, name, value)
    endfor
  endfu

  fu! esearch#win#get(tabnr, winnr, name) abort
    return gettabwinvar(a:tabnr, a:winnr, a:name[(a:name =~# '^w:' ? 2 : 0):])
  endfu

  fu! esearch#win#find(handle) abort
    return s:ViewTracer.find(a:handle)
  endfu

  " implements Vital api
  fu! s:Guard.store(targets) abort dict
    let [tabnr, winnr] = s:ViewTracer.find(self.handle)

    for name in a:targets
      let self._resources[name] = esearch#win#get(tabnr, winnr, name)
    endfor

    return self
  endfu
endif

fu! s:Guard.restore() abort dict
  if esearch#win#exists(self.handle)
    call esearch#win#bulk_let(self.handle, self._resources)
  endif
endfu
