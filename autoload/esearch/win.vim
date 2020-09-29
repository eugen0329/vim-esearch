let s:window_id  = esearch#util#counter()

" Utility functions to work with windows. Includes:
" - normalized windows api
" - guards to set/reset windows configs without enter

fu! esearch#win#guard() abort
  return s:Guard
endfu

let s:Guard = {'_resources': {}}

fu! s:Guard.new(handle) abort dict
  let instance = copy(self)
  let instance.handle = a:handle
  return instance
endfu

"""""""""""""""""""""""""""""""""""""""

fu! esearch#win#setter() abort
  return s:Setter
endfu

let s:Setter = {'_resources': {}}

fu! s:Setter.new(handle) abort dict
  let instance = copy(self)
  let instance.handle = a:handle
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
        \ s:Setter.new(a:handle).apply)
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

  fu! s:Setter.apply(variables) abort dict
    for [name, value] in items(a:variables)
      if name =~# '^w:'
        call nvim_win_set_var(self.handle, name[2:], value)
      elseif name =~# '^&l:'
        throw printf('Redundant &l: specified in "%s": please, use "&%s" format', name, name[3:])
      elseif name =~# '^&'
        call nvim_win_set_option(self.handle, name[1:], value)
      else
        throw printf('Unknown value "%s" was specified', name)
      endif
    endfor
  endfu

  " implements Vital api
  fu! s:Guard.store(targets) abort dict
    for name in a:targets
      if name =~# '^w:'
        let value = nvim_win_get_var(self.handle, name[2:])
      elseif name =~# '^&l:'
        throw printf('Redundant &l: specified in "%s": please, use "&%s" format', name, name[3:])
      elseif name =~# '^&'
        let value = nvim_win_get_option(self.handle, name[1:])
      else
        throw printf('Unknown value "%s" was specified', name)
      endif

      let self._resources[name] = value
    endfor

    return self
  endfu

  fu! s:Guard.restore() abort dict
    if esearch#win#exists(self.handle)
      call s:Setter.new(self.handle).apply(self._resources)
    endif
  endfu
else
  let s:ViewTracer = vital#esearch#import('Vim.ViewTracer')

  fu! esearch#win#exists(handle) abort
    return s:ViewTracer.exists(a:handle)
  endfu

  fu! esearch#win#trace(...) abort
    " Neovim works by matching window vars, so using counter prevents from
    " matching different windows with the same variables defined.
    let [tabnr, winnr] = a:0 ? a:000 : [tabpagenr(), winnr()]
    call settabwinvar(tabnr, winnr, 'elearch', s:window_id.next())
    return s:ViewTracer.trace_window(tabnr, winnr)

    let [tabnr, bufnr]
    let w:esearch = s:window_id.next()
    return call('trace_window', a:000, s:ViewTracer)
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

  fu! s:Setter.apply(variables) abort dict
    let [tabnr, winnr] = s:ViewTracer.find(self.handle)
    for [name, value] in items(a:variables)
      if name =~# '^w:'
        call settabwinvar(tabnr, winnr, name[2:], value)
      elseif name =~# '^&l:'
        throw printf('Redundant &l: specified in "%s": please, use "&%s" format', name, name[3:])
      elseif name =~# '^&'
        call settabwinvar(tabnr, winnr, name, value)
      else
        throw printf('Unknown value "%s" was specified', name)
      endif
    endfor
  endfu

  " implements Vital api
  fu! s:Guard.store(targets) abort dict
    let [tabnr, winnr] = s:ViewTracer.find(self.handle)
    for name in a:targets
      if name =~# '^w:'
        let value = gettabwinvar(tabnr, winnr, name[2:])
      elseif name =~# '^&l:'
        throw printf('Redundant &l: specified in "%s": please, use "&%s" format', name, name[3:])
      elseif name =~# '^&'
        let value = gettabwinvar(tabnr, winnr, name)
      else
        throw printf('Unknown value "%s" was specified', name)
      endif

      let self._resources[name] = value
    endfor

    return self
  endfu

  fu! s:Guard.restore() abort dict
    if esearch#win#exists(self.handle)
      call s:Setter.new(self.handle).apply(self._resources)
    endif
  endfu
endif
