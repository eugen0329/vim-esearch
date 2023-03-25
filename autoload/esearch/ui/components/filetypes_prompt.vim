let s:Dict  = vital#esearch#import('Data.Dict')
let s:FiletypesPrompt = {}

fu! s:FiletypesPrompt.init(adapter, filetypes) abort
  return extend(copy(self), {
        \ 'filetypes': a:filetypes,
        \ 'adapter': a:adapter,
        \})
endfu

fu! s:FiletypesPrompt.update(msg, model) abort
  return [a:model, ['cmd.none']]
endfu

fu! s:FiletypesPrompt.view(model, ...) abort
  if empty(a:model.filetypes) || empty(a:model.adapter.filetypes)
    return [[], ['cmd.none']]
  endif

  let chunks = []
  let available_filetypes = s:Dict.make_index(a:model.adapter.filetypes)
  for filetype in split(a:model.filetypes)
    let hl = get(available_filetypes, filetype) ? 'Typedef' : 'None'
    call add(chunks, [['<.'.filetype.'>', hl]])
  endfor

  return [esearch#util#join(chunks, [' ', 'None']), ['cmd.none']]
endfu

fu! esearch#ui#components#filetypes_prompt#import() abort
  return s:FiletypesPrompt
endfu
