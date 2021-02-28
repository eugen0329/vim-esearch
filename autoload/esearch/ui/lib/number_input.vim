let s:String    = vital#esearch#import('Data.String')
let s:Dict    = vital#esearch#import('Data.Dict')
let s:focused_inc = s:Dict.make_index(["\<enter>", "\<right>", 'l'])
let s:focused_dec = s:Dict.make_index(["\<left>", 'h'])
let s:is_num = s:Dict.make_index(range(0, 9))
let s:is_bs = s:Dict.make_index(["\<bs>", "\<c-h>"])
let s:is_reset = s:Dict.make_index(["\<del>"])
let s:NumberInput = {'type': 'NumberInput'}

fu! s:NumberInput.init(val, range, msg, inc, dec) abort
  return extend(copy(self), {
        \ 'handled': 0,
        \ 'focused': 0,
        \ 'default': a:val,
        \ 'val': a:val,
        \ 'msg': a:msg,
        \ 'range': a:range,
        \ 'inc': a:inc,
        \ 'dec': a:dec,
        \ 'is_inc': s:Dict.make_index(a:inc),
        \ 'is_dec': s:Dict.make_index(a:dec),
        \ })
endfu

fu! s:NumberInput.update(msg, model) abort
  if a:msg[0] ==# 'KeyPressed'
    let key = a:msg[1]

    if get(a:model.is_inc, key)
      return s:add(a:msg, a:model, 1)
    elseif get(a:model.is_dec, key)
      return s:add(a:msg, a:model, -1)
    elseif a:model.focused
      if get(s:focused_inc, key)
        return s:add(a:msg, a:model, 1)
      elseif get(s:focused_dec, key)
        return s:add(a:msg, a:model, -1)
      elseif get(s:is_num, key)
        return s:append(a:msg, a:model, key)
      elseif get(s:is_bs, key)
        return s:delete(a:msg, a:model)
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

fu! s:NumberInput.view(model) abort
  return [[], ['cmd.none']]
endfu

fu! s:add(msg, model, num) abort
  return s:set(a:msg, a:model, a:model.val + str2nr(a:num))
endfu

fu! s:append(msg, model, num) abort
  return s:set(a:msg, a:model, str2nr(string(a:model.val).a:num))
endfu

fu! s:delete(msg, model) abort
  return s:set(a:msg, a:model, a:model.val / 10)
endfu

fu! s:set(msg, model, val) abort
  let val = esearch#util#clip(a:val, a:model.range[0], a:model.range[1])
  return [extend(a:model, {'handled': a:msg, 'val': val}),
        \ ['cmd.emit', [a:model.msg, val]]]
endfu

fu! esearch#ui#lib#number_input#import() abort
  return copy(s:NumberInput)
endfu
