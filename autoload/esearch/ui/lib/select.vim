let s:String    = vital#esearch#import('Data.String')
let s:Dict    = vital#esearch#import('Data.Dict')
let s:focused_next = s:Dict.make_index(["\<enter>", "\<right>", 'l'])
let s:focused_prev = s:Dict.make_index(["\<left>", 'h'])
let s:is_num = s:Dict.make_index(range(0, 9))
let s:is_reset = s:Dict.make_index(["\<bs>", "\<c-h>", "\<del>"])
let s:Select = {'type': 'Select'}

fu! s:Select.init(val, options, msg, inc, dec) abort
  return extend(copy(self), {
        \ 'handled': 0,
        \ 'focused': 0,
        \ 'default': a:val,
        \ 'val': a:val,
        \ 'msg': a:msg,
        \ 'options': a:options,
        \ 'inc': a:inc,
        \ 'dec': a:dec,
        \ 'is_next': s:Dict.make_index(a:inc),
        \ 'is_prev': s:Dict.make_index(a:dec),
        \ })
endfu

fu! s:Select.update(msg, model) abort
  if a:msg[0] ==# 'KeyPressed'
    let key = a:msg[1]

    if get(a:model.is_next, key)
      return s:cycle(a:msg, a:model, 1)
    elseif get(a:model.is_prev, key)
      return s:cycle(a:msg, a:model, -1)
    elseif a:model.focused
      if get(s:focused_next, key)
        return s:cycle(a:msg, a:model, 1)
      elseif get(s:focused_prev, key)
        return s:cycle(a:msg, a:model, -1)
      elseif get(s:is_reset, key)
        return s:set(a:msg, a:model, a:model.default)
      endif
    endif

    return [a:model, ['cmd.none']]
  elseif a:msg[0] ==# 'CursorFocused'
    return [extend(a:model, {'focused': 1}), ['cmd.none']]
  elseif a:msg[0] ==# 'CursorBlurred'
    return [extend(a:model, {'focused': 0}), ['cmd.none']]
  else
    throw 'unexpected message '.string(a:msg)
  endif
endfu

fu! s:Select.view(model) abort
  return [[['NONE', a:model.hint.' after ('.a:model.val.')']], ['cmd.none']]
endfu

fu! s:cycle(msg, model, direction) abort
  let val = esearch#ui#util#c(a:model.options, a:model.val, a:direction)
  return s:set(a:msg, a:model, val)
endfu

fu! s:set(msg, model, val) abort
  return [extend(a:model, {'handled': a:msg, 'val': a:val}), ['cmd.emit', [a:model.msg, a:val]]]
endfu

fu! esearch#ui#lib#select#import() abort
  return s:Select
endfu
