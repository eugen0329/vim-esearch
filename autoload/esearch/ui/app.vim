let s:FiletypesInput = esearch#ui#locations#filetypes_input#import()
let s:PatternInput = esearch#ui#locations#pattern_input#import()
let s:MainMenu = esearch#ui#locations#main_menu#import()
let s:GlobsInput = esearch#ui#locations#globs_input#import()
let s:PathsInput = esearch#ui#locations#paths_input#import()
let s:GlobsMenu = esearch#ui#locations#globs_menu#import()

let g:esearch#ui#run#palette = {
      \ '': '',
      \}

fu! esearch#ui#app#run(esearch) abort
  " TODO move to session
  call extend(a:esearch, {
        \ 'cmdline': '',
        \ 'cmdpos': -1,
        \ })
  return esearch#ui#runtime#loop(s:App, a:esearch).esearch
endfu

let s:App = {}

fu! s:App.init(...) abort dict
  let session = {}
  let [location, cmd] = s:PatternInput.init(a:1, session)
  return [{
        \ 'location': location,
        \ 'esearch': a:1,
        \}, cmd]
endfu

let g:debug = []

fu! s:App.update(msg, model) abort dict
  if a:msg[0] ==# 'Route'
    let route = a:msg[1]

    if route[0] ==# 'quit'
      return [a:model, ['cmd.quit']]
    elseif route[0] ==# 'paths_input'
      return s:route_to(route, s:PathsInput, a:model)
    elseif route[0] ==# 'globs_input'
      return s:route_to(route, s:GlobsInput, a:model)
    elseif route[0] ==# 'main_menu'
      return s:route_to(route, s:MainMenu, a:model)
    elseif route[0] ==# 'globs_menu'
      return s:route_to(route, s:GlobsMenu, a:model)
    elseif route[0] ==# 'pattern_input'
      return s:route_to(route, s:PatternInput, a:model)
    elseif route[0] ==# 'filetypes_input'
      return s:route_to(route, s:FiletypesInput, a:model)
    else
      throw 'unexpected message '.string(a:msg)
    endif
  else
    let [location, cmd] = a:model.location.update(a:msg, a:model.location)
    return [extend(a:model, {'location': location, 'esearch': location.esearch}), cmd]
  endif
endfu

fu! s:route_to(route, handler, model) abort
  let session = extend(a:model.location.session, {'route': a:route})
  let [location, cmd] = a:handler.init(a:model.esearch, session)
  return [extend(a:model, {'location': location}), cmd]
endfu

fu! s:App.view(model) abort dict
  return a:model.location.view(a:model.location)
endfu
