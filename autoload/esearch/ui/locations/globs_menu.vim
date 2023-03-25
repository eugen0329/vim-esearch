let s:VerticalMenu = esearch#ui#context#vertical_menu#import()
let s:Link = esearch#ui#lib#link#import()
let s:Dict  = vital#esearch#import('Data.Dict')
" let s:is_cancel = s:Dict.make_index(["\<esc>", "\<c-c>", 'q'])
let s:is_next = s:Dict.make_index(['l', "\<right>", "\<tab>"])
let s:is_prev = s:Dict.make_index(['h', "\<left>", "\<s-tab>"])
let s:is_del = s:Dict.make_index(['x', 'd', "\<bs>", "\<del>"])
let s:is_edit = s:Dict.make_index(['i', 'a'])
let s:is_push = s:Dict.make_index(['I', 'A', "\<c-p>"])
let s:Menu = esearch#ui#lib#menu#import()

let s:GlobsMenu = {}
fu! s:GlobsMenu.init(esearch, session) abort
  let adapter = a:esearch._adapter

  let items = map(copy(a:esearch.globs.list),
        \ "s:Link.init(['globs_input', {'i': v:key}], [], 'ItemKeyPressed')")
  let items[-1].focused = 1

  let [menu, menu_cmd] = s:Menu.init({
        \ 'esearch': a:esearch,
        \ 'cursor': len(items) - 1,
        \ 'quit_msg': 'Quit',
        \ 'is_next': s:is_next,
        \ 'is_prev': s:is_prev,
        \})

  let model = extend(copy(self), {
        \ 'esearch': a:esearch,
        \ 'session': a:session,
        \ 'menu': menu,
        \ 'items': items,
        \})

  return [model, ['cmd.batch', [
        \ ['cmd.context', s:VerticalMenu.new(1)],
        \ menu_cmd]]]
endfu

fu! s:GlobsMenu.update(msg, model) abort
  if a:msg[0] ==# 'Quit'
    return [a:model, ['cmd.route', ['main_menu']]]
  elseif a:msg[0] ==# 'ItemKeyPressed'
    let key = a:msg[1]

    if get(s:is_del, key)
      let i = index(a:model.items, a:msg[2])
      call remove(a:model.esearch.globs.list, i)
      if empty(a:model.esearch.globs.list) | return [a:model, ['cmd.route', ['main_menu']]] | endif

      call remove(a:model.items, i)
      return [a:model, ['cmd.cursor', 'CursorFocused', i == 0 ? 0 : i - 1]]
    elseif get(s:is_edit, key)
      let i = index(a:model.items, a:msg[2])
      let cmdpos = key ==# 'a' ? -1 : 1
      return [a:model, ['cmd.route', ['globs_input', {'i': i, 'cmdpos': cmdpos}]]]
    elseif get(s:is_push, key)
      return [a:model, ['cmd.route', ['globs_input', {'push': 1}]]]
    endif

    return [a:model, ['cmd.none']]
  endif

  let [menu, menu_msg] = a:model.menu.update(a:msg, a:model.menu)
  return [extend(a:model, {'menu': menu}), ['cmd.batch', [menu_msg]]]
endfu

fu! s:GlobsMenu.view(model) abort
  let ellipsis = g:esearch#has#unicode ? g:esearch#unicode#ellipsis : '...'
  let chunks = [[a:model.esearch.adapter.' '.ellipsis.' ', 'None']]

  let items = []
  for i in range(len(a:model.esearch.globs.list))
    let glob = a:model.esearch.globs.list[i]
    " let hl = a:model.items[i].focused ? 'Function' : 'None'
    call add(items, [[glob.opt . glob.convert(a:model.esearch).arg, 'None']])

    if a:model.items[i].focused
      let items[-1] = esearch#highlight#bg(items[-1], 'Visual')
    endif
  endfor

  let chunks = chunks + esearch#util#join(items, [' ', 'None'])
  let [menu_chunks, menu_msg] = a:model.menu.view(a:model.menu, chunks)
  return [menu_chunks, ['cmd.batch', [['cmd.place', a:model.items], menu_msg]]]
endfu

fu! esearch#ui#locations#globs_menu#import() abort
  return s:GlobsMenu
endfu
