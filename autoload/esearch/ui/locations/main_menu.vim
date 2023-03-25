let s:LiveUpdateGetchar = esearch#ui#context#live_update_getchar#import()
let s:LiveUpdate = esearch#ui#context#live_update#import()
let s:VerticalMenu = esearch#ui#context#vertical_menu#import()
let s:NumberInput = esearch#ui#lib#number_input#import()
let s:Select = esearch#ui#lib#select#import()
let s:Link = esearch#ui#lib#link#import()
let s:PatternInputPrompt = esearch#ui#components#pattern_input_prompt#import()
let s:PathsPrompt = esearch#ui#components#paths_prompt#import()
let s:Dict  = vital#esearch#import('Data.Dict')
let s:List = vital#esearch#import('Data.List')
let s:is_cancel = s:Dict.make_index(["\<esc>", "\<c-c>", 'q'])
let s:is_next   = s:Dict.make_index(["\<c-j>", 'j', "\<down>"])
let s:is_prev     = s:Dict.make_index(["\<c-k>", 'k', "\<up>"])
let s:Menu = esearch#ui#lib#menu#import()

let s:hints = {
      \ 'paths':     'search only in paths',
      \ 'filetypes': 'search only in filetypes',
      \ 'globs':     'filter paths',
      \ 'case':      'case match',
      \ 'regex':     'regex match',
      \ 'textobj':   'textobj match',
      \ 'after':     'more/less lines after',
      \ 'before':    'more/less lines before',
      \ 'context':   'more/less lines around',
      \}
" g:esearch#has#unicode ? g:esearch#unicode#ellipsis : '...'
let s:up     = '['.(g:esearch#has#unicode ? g:esearch#unicode#up.g:esearch#unicode#ellipsis   : ' ^_').']'
let s:down   = '['.(g:esearch#has#unicode ? g:esearch#unicode#down.g:esearch#unicode#ellipsis : ' v_').']'
let s:updown = '['.(g:esearch#has#unicode ? g:esearch#unicode#up.g:esearch#unicode#down       : ' ^v').']'
let s:icons = {
      \ 'paths':     { '0': ['[./]', 'Comment'], '1': ['[./]', 'Directory'] },
      \ 'globs':     { '0': ['[!/]', 'Comment'], '1': ['[!/]', 'Special'  ] },
      \ 'filetypes': { '0': ['[ft]', 'Comment'], '1': ['[ft]', 'Typedef'  ] },
      \ 'case': {
      \   'ignore':    ['(?i)', 'Comment'],
      \   'sensitive': ['[Cs]', 'Constant'],
      \   'smart':     ['[Sc]', 'Identifier'],
      \   '_':         ['[c]',  'Comment'],
      \ },
      \ 'regex': {
      \   'literal': ['\.\*', 'Comment'],
      \   '_':       ['/.*/',  'String'],
      \ },
      \ 'textobj': {
      \   'word': ['[\b]', 'Keyword'],
      \   'line': ['[^$]',  'String'],
      \   '_':    ['[""]', 'Comment'],
      \ },
      \ 'after':   {'0': [s:down,   'Comment'], '_': [s:down,   'Number']},
      \ 'before':  {'0': [s:up,     'Comment'], '_': [s:up,     'Number']},
      \ 'context': {'0': [s:updown, 'Comment'], '_': [s:updown, 'Number']},
      \}

let s:MainMenu = {}
fu! s:MainMenu.init(esearch, session) abort
  let adapter = a:esearch._adapter

  let items = {
        \ 'paths':   s:Link.init(['paths_input'], ['p', "\<c-p>"]),
        \ 'case':    s:Select.init(a:esearch.case,    adapter.case,    'CaseChanged',    ['s', "\<c-s>"], []),
        \ 'regex':   s:Select.init(a:esearch.regex,   adapter.regex,   'RegexChanged',   ['r', "\<c-r>"], []),
        \ 'textobj': s:Select.init(a:esearch.textobj, adapter.textobj, 'TextobjChanged', ['t', "\<c-t>"], []),
        \ 'after':   s:NumberInput.init(a:esearch.after,   [0, 1000],  'AfterChanged',   ['a',  "\<c-a>"], ['A']),
        \ 'before':  s:NumberInput.init(a:esearch.before,  [0, 1000],  'BeforeChanged',  ['b',  "\<c-b>"], ['B']),
        \ 'context': s:NumberInput.init(a:esearch.context, [0, 1000],  'ContextChanged', ['c'], ['C']),
        \}
  if !empty(adapter.globs)
    let items['globs'] = s:Link.init([(empty(a:esearch.globs.list) ? 'globs_input' : 'globs_menu'), {'push': 1}], ['g', "\<c-g>"])
  endif
  if !empty(adapter.filetypes)
    let items['filetypes'] = s:Link.init(['filetypes_input'], ['f', "\<c-f>"])
  endif
  let items.case.focused = 1
  let prompt = s:PatternInputPrompt.init(a:esearch)
  let [menu, menu_cmd] = s:Menu.init({'quit_msg': 'Quit', 'is_next': s:is_next, 'is_prev': s:is_prev})
  let model = extend(extend(copy(self), {
        \ 'esearch': a:esearch,
        \ 'session': a:session,
        \ 'menu': menu,
        \ 'prompt': prompt,
        \ 'paths_prompt': s:PathsPrompt.init(a:esearch.cwd, a:esearch.paths, [' ', 'None'], {'normal': 'None'}),
        \}), items)
  return [model, ['cmd.batch', [
        \ ['cmd.context', s:VerticalMenu.new(len(items) + len([prompt]))],
        \ ['cmd.context', s:LiveUpdateGetchar.new(model)],
        \ ['cmd.force_redraw'],
        \ menu_cmd]]]
endfu

fu! s:MainMenu.update(msg, model) abort
  if a:msg[0] ==# 'Quit'
    return [a:model, ['cmd.route', ['pattern_input']]]
  elseif a:msg[0] ==# 'AfterChanged'
    return s:set(a:msg, a:model, 'after')
  elseif a:msg[0] ==# 'BeforeChanged'
    return s:set(a:msg, a:model, 'before')
  elseif a:msg[0] ==# 'ContextChanged'
    return s:set(a:msg, a:model, 'context')
  elseif a:msg[0] ==# 'CaseChanged'
    return s:set(a:msg, a:model, 'case')
  elseif a:msg[0] ==# 'RegexChanged'
    return s:set(a:msg, a:model, 'regex')
  elseif a:msg[0] ==# 'TextobjChanged'
    return s:set(a:msg, a:model, 'textobj')
  elseif a:msg[0] ==# 'LiveExecuted'
    return [a:model, ['cmd.none']]
  else
    let [menu, menu_msg] = a:model.menu.update(a:msg, a:model.menu)
    let [prompt, prompt_msg] = a:model.prompt.update(a:msg, a:model.prompt)
    return [extend(a:model, {'menu': menu, 'prompt': prompt}),
          \ ['cmd.batch', [prompt_msg, menu_msg]]]
  endif
endfu

fu! s:MainMenu.view(model) abort
  let [rows, inputs] = [[], []]
  let hl = {'Preview': 'Comment'}

  for slider in ['case', 'regex', 'textobj', 'after', 'before', 'context']
    call add(rows, s:view_slider(a:model, slider, hl))
    call add(inputs, a:model[slider])
  endfor

  call add(rows, s:view_paths(a:model, hl))
  call add(inputs, a:model.paths)

  if has_key(a:model, 'filetypes')
    call add(rows, s:view_filetypes(a:model, hl))
    call add(inputs, a:model.filetypes)
  endif

  if has_key(a:model, 'globs')
    call add(rows, s:view_globs(a:model, hl))
    call add(inputs, a:model.globs)
  endif

  let chunks = esearch#ui#render#table(rows)
  let [menu_chunks, menu_msg] = a:model.menu.view(a:model.menu, chunks)
  let [prompt_chunks, prompt_msg] = a:model.prompt.view(a:model.prompt)

  return [menu_chunks + prompt_chunks,
        \ ['cmd.batch', [['cmd.place', inputs], menu_msg, prompt_msg]]]
endfu

fu! s:view_slider(model, slider, hl) abort
  let adapter = a:model.esearch._adapter
  let Preview = a:hl.Preview
  let input = a:model[a:slider]

  let keys = [s:keys(input), 'None']
  let icon = get(s:icons[a:slider], input.val, s:icons[a:slider]._)
  let hint = [s:hints[a:slider].' ', 'None']
  if input.type ==# 'Select'
    let opt = adapter[a:slider][input.val].opt
    let preview = [['('.input.val.(empty(opt) ? '' : ': ').opt.')', Preview]]
  else
    let preview = [['('.(input.val == 0 ? 'none' : adapter[a:slider].opt.' '.input.val).')', Preview]]
  endif

  return s:view_selectable(input, [[keys], [icon], [hint] + preview])
endfu

fu! s:view_paths(model, hl) abort
  let input = a:model.paths
  let Preview = a:hl.Preview
  let keys = [s:keys(input), 'None']
  let icon = s:icons.paths[!empty(a:model.esearch.paths)]
  let hint = [s:hints.paths.' ', 'None']
  let [paths_chunks, cmd] = a:model.paths_prompt.view(a:model.paths_prompt)
  if empty(paths_chunks)
    let preview = [['(none)', Preview]]
  else
    let preview = [['(', Preview]] + paths_chunks + [[')', Preview]]
  endif

  return s:view_selectable(input, [[keys], [icon], [hint] + preview])
endfu

fu! s:view_filetypes(model, hl) abort
  let input = a:model.filetypes
  let Preview = a:hl.Preview

  let keys = [s:keys(input), 'None']
  let icon = s:icons.filetypes[!empty(a:model.esearch.filetypes)]
  let hint = [s:hints.filetypes.' ', 'None']

  if empty(a:model.esearch.filetypes)
    let preview = [['(none)', Preview]]
  else
    let preview = [
          \ ['(', Preview],
          \ [a:model.esearch._adapter.filetypes2args(a:model.esearch.filetypes), Preview],
          \ [')', Preview]]
  endif

  return s:view_selectable(input, [[keys], [icon], [hint] + preview])
endfu

fu! s:view_globs(model, hl) abort
  let input = a:model.globs
  let Preview = a:hl.Preview

  let keys = [s:keys(input), 'None']
  let icon = s:icons.globs[!empty(a:model.esearch.globs.list)]
  let hint = [s:hints.globs.' ', 'None']
  let [paths_chunks, cmd] = a:model.paths_prompt.view(a:model.paths_prompt)

  if empty(a:model.esearch.globs.list)
    let preview = [['(none)', Preview]]
  else
    let preview = []
    for g in a:model.esearch.globs.list
      call add(preview, [[g.opt . g.convert(a:model.esearch).arg, Preview]])
    endfor
    let preview = [['(', Preview]] + esearch#util#join(preview, [' ', Preview]) + [[')', Preview]]
  endif

  return s:view_selectable(input, [[keys], [icon], [hint] + preview])
endfu

fu! s:view_selectable(input, view) abort
  if !a:input.focused | return a:view | endif
  return map(a:view, "esearch#highlight#bg(v:val, 'Visual')")
endfu

fu! s:add(table, input, row) abort
  if a:input.focused
    call add(a:table, map(a:row, "esearch#highlight#bg(v:val, 'Visual')"))
  else
    call add(a:table, a:row)
  endif
endfu

fu! s:keys(input) abort
  if has_key(a:input, 'keys')
    let keys = empty(a:input.keys) ? 0 : [a:input.keys[0]]
  else
    let keys = filter([get(a:input.inc, 0), get(a:input.dec, 0)], '!empty(v:val)')
  endif
  return empty(keys) ? '<nop>' : join(map(keys, 'strtrans(v:val)'), '/')
endfu

fu! s:set(msg, model, key) abort
  let a:model.esearch[a:key] = a:msg[1]
  let esearch = copy(a:model.esearch)
  let pattern_text = a:model.session.pattern_state[0]
  if empty(pattern_text) | return [a:model, ['cmd.none']] | endif
  let esearch.pattern = deepcopy(esearch.pattern)
  call esearch.pattern.push(pattern_text)
  return [a:model, ['cmd.force_exec', esearch, esearch.live_update_menu_debounce_wait]]
endfu

fu! esearch#ui#locations#main_menu#import() abort
  return s:MainMenu
endfu
