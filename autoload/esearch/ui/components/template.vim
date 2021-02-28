let s:Template = {}

fu! s:Template.init(esearch) abort
  return [extend(copy(self), {
        \ 'esearch': a:esearch,
        \}), ['cmd.none']]
endfu

fu! s:Template.update(msg, model) abort
  if a:msg[0] ==# 'Message'
    return [extend(a:model, {}), ['cmd.none']]
  else
    throw 'unexpected msg '.string(a:msg)
  endif
endfu

fu! s:Template.view(model) abort
  return [[], ['cmd.none']]
endfu

fu! esearch#ui#components#template#import() abort
  return s:Template
endfu
