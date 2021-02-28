let s:String    = vital#esearch#import('Data.String')
let s:Dict    = vital#esearch#import('Data.Dict')
let s:focused_keys = s:Dict.make_index(["\<enter>"])
let s:focused_prev = s:Dict.make_index(["\<left>", 'h'])
let s:is_num = s:Dict.make_index(range(0, 9))
let s:is_reset = s:Dict.make_index(["\<bs>", "\<c-h>", "\<del>"])
let s:Link = {'type': 'Link'}

fu! s:Link.init(ref, keys, ...) abort
  return extend(copy(self), {
        \ 'handled': 0,
        \ 'focused': 0,
        \ 'ref': a:ref,
        \ 'keys': a:keys,
        \ 'onkeypress': get(a:, 1),
        \ 'is_key': s:Dict.make_index(a:keys),
        \ })
endfu

fu! s:Link.update(msg, model) abort
  if a:msg[0] ==# 'KeyPressed'
    let key = a:msg[1]

    if get(a:model.is_key, key)
      return [a:model, ['cmd.route', a:model.ref]]
    elseif a:model.focused
      if get(s:focused_keys, key)
        return [a:model, ['cmd.route', a:model.ref]]
      elseif !empty(a:model.onkeypress)
        return [a:model, ['cmd.emit', [a:model.onkeypress, key, a:model]]]
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

fu! s:Link.view(model) abort
  return [[['NONE', a:model.hint.' after ('.a:model.val.')']], ['cmd.none']]
endfu

fu! esearch#ui#lib#link#import() abort
  return s:Link
endfu
