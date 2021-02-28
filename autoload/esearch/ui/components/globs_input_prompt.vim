let s:GlobsInputPrompt = {}

fu! s:GlobsInputPrompt.init(esearch) abort
  return extend(copy(self), {
        \ 'esearch': a:esearch,
        \ 'globs': a:esearch.globs,
        \ 'adapter': a:esearch._adapter,
        \})
endfu

fu! s:GlobsInputPrompt.update(msg, model) abort
  return [a:model, ['cmd.none']]
endfu

fu! s:GlobsInputPrompt.view(model, ...) abort
  if empty(a:model.adapter.globs) | return [[], ['cmd.none']] | endif

  let globs = map(copy(a:model.globs.list), 'v:val.opt . v:val.convert(a:model.esearch).arg')
  let chunks = join(globs + [a:model.globs.kinds.peek().icon." '"]) 

  return [[[chunks, 'None']], ['cmd.none']]
endfu

fu! esearch#ui#components#globs_input_prompt#import() abort
  return s:GlobsInputPrompt
endfu
