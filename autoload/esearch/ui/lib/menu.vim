let s:Dict  = vital#esearch#import('Data.Dict')
let s:is_cancel = s:Dict.make_index(["\<esc>", "\<c-c>", 'q'])
let s:Menu = {'type': 'Menu'}

fu! s:Menu.init(opts) abort
  let model = extend(extend(copy(self), {'cursor': 0, 'items': []}), a:opts)
  return [model, ['cmd.none']]
endfu

fu! s:Menu.update(msg, model) abort
  if a:msg[0] ==# 'KeyPressed'
    let key = a:msg[1]

    if get(a:model.is_next, key)
      return s:move_cursor(a:model, 1)
    elseif get(a:model.is_prev, key)
      return s:move_cursor(a:model, -1)
    elseif get(s:is_cancel, key)
      return [a:model, ['cmd.emit', [a:model.quit_msg]]]
    else
      let cmds = []

      for i in range(len(a:model.items))
        let [a:model.items[i], cmd] = a:model.items[i].update(a:msg, a:model.items[i])
        call add(cmds, cmd)

        " focuse the handled item and leave
        if i != a:model.cursor && a:model.items[i].handled is# a:msg
          call add(cmds, ['cmd.batch', [
                \ ['cmd.cursor', 'CursorBlurred', a:model.cursor],
                \ ['cmd.cursor', 'CursorFocused', i],
                \]])
          break
        endif
      endfor

      return [a:model, ['cmd.batch', cmds]]
    endif
  elseif a:msg[0] ==# 'Place'
    return [extend(a:model, {'items': a:msg[1]}), ['cmd.none']]
  elseif a:msg[0] ==# 'CursorFocused'
    let focused_item = a:model.items[a:msg[1]]
    let [a:model.items[a:msg[1]], cmd] = focused_item.update(a:msg, focused_item)
    return [extend(a:model, {'cursor': a:msg[1]}), cmd]
  elseif a:msg[0] ==# 'CursorBlurred'
    let blurred_item = a:model.items[a:msg[1]]
    let [a:model.items[a:msg[1]], cmd] = blurred_item.update(a:msg, blurred_item)
    return [a:model, cmd]
  else
    throw 'unexpected message '.string(a:msg[0])
  endif
endfu

fu! s:Menu.view(model, ...) abort
  return [a:0 ? a:1 : [], ['cmd.getchar', 'KeyPressed']]
endfu

" TODO cycle
fu! s:move_cursor(model, delta) abort
  let cursor = (a:model.cursor + a:delta) % len(a:model.items)
  if cursor < 0 | let cursor += len(a:model.items) | endif

  return [a:model, ['cmd.batch', [
        \   ['cmd.cursor', 'CursorBlurred', a:model.cursor],
        \   ['cmd.cursor', 'CursorFocused', cursor]]]]
endfu

fu! esearch#ui#lib#menu#import() abort
  return s:Menu
endfu
