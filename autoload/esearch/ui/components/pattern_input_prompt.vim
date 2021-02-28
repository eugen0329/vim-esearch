let s:SearchInputPrompt = {}

fu! s:SearchInputPrompt.init(esearch) abort
  return extend(copy(self), {
        \ 'esearch': a:esearch,
        \ 'pattern': a:esearch.pattern,
        \ })
endfu

fu! s:SearchInputPrompt.update(msg, model) abort
  return [a:model, ['cmd.none']]
endfu

fu! s:SearchInputPrompt.view(model) abort
  let [view, esearch] = [[], a:model.esearch]


  let pattern = map(copy(a:model.pattern.list), 'v:val.opt . v:val.convert(a:model.esearch).arg')
  let chunks = join(pattern + [a:model.pattern.kinds.peek().icon]) 

  return [[
        \   [esearch.adapter.' ', 'None'],
        \   [chunks, 'None'],
        \   [s:icon_of(esearch, 'case', '>'), 'None'],
        \   [s:icon_of(esearch, 'regex', '>'), 'None'],
        \   [s:icon_of(esearch, 'textobj', '>'), 'None'],
        \   [' ', 'None'],
        \ ],
        \ ['cmd.none']]
endfu

fu! s:icon_of(esearch, model, fallback) abort
  let icon = a:esearch._adapter[a:model][a:esearch[a:model]].icon
  return empty(icon) ? '>' : icon
endfu

fu! esearch#ui#components#pattern_input_prompt#import() abort
  return s:SearchInputPrompt
endfu
