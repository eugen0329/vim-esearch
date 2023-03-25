let s:Lualine = esearch#ui#context#lualine#import()
let s:PatternInputPrompt = esearch#ui#components#pattern_input_prompt#import()
let s:LiveUpdate = esearch#ui#context#live_update#import()
let s:PersistentStatusline = esearch#ui#context#persistent_statusline#import()
let s:ConfigurationsPrompt = esearch#ui#components#configurations_prompt#import()

cnoremap <expr><plug>(esearch-push-pattern)  esearch#ui#runtime#onpress(['PushPattern'])
cnoremap <expr><plug>(esearch-open-menu)     esearch#ui#runtime#onpress(['KeyPressed', 'main_menu'])
cnoremap <expr><plug>(esearch-cycle-regex)   esearch#ui#runtime#onpress(['KeyPressed', 'regex'])
cnoremap <expr><plug>(esearch-cycle-case)    esearch#ui#runtime#onpress(['KeyPressed', 'case'])
cnoremap <expr><plug>(esearch-cycle-textobj) esearch#ui#runtime#onpress(['KeyPressed', 'textobj'])

let s:keymaps = [
      \ ['c', '<c-o>',      '<plug>(esearch-open-menu)'    ],
      \ ['c', '<c-r><c-r>', '<plug>(esearch-cycle-regex)'  ],
      \ ['c', '<c-s><c-s>', '<plug>(esearch-cycle-case)'   ],
      \ ['c', '<c-t><c-t>', '<plug>(esearch-cycle-textobj)'],
      \ ['c', '<c-p>',      '<plug>(esearch-push-pattern)' ],
      \]

let s:PatternInput = {}

fu! s:PatternInput.init(esearch, session) abort
  " TODO figure out better live update handling than using executed_cmdline
  let model = extend(copy(self), {
        \ 'keymaps': s:keymaps,
        \ 'esearch': a:esearch,
        \ 'executed_cmdline': '',
        \ 'configurations_prompt': s:ConfigurationsPrompt.init(a:esearch),
        \ 'prompt': s:PatternInputPrompt.init(a:esearch),
        \})

  if has_key(a:session, 'pattern_state')
    let model.session = a:session
  else
    let pattern = a:esearch.pattern.try_pop()
    let session = {
        \   'pattern_state': [pattern.str, -1],
        \   'pattern_input_select': !empty(pattern.str),
        \ }
    let model.session = extend(a:session, session)
  endif

  let cmds = []
  if g:esearch.lualine_integration
    let cmds += [['cmd.context', s:Lualine.new(model)]]
  endif
  let cmds += [
        \ ['cmd.context', s:PersistentStatusline.new(model)],
        \ ['cmd.statusline', [['', 'None']]],
        \ ['cmd.context', s:LiveUpdate.new(model, 'CmdlineChanged')],
        \]

  if !empty(model.session.pattern_state)
    call add(cmds, s:force_exec_cmd(model, model.session.pattern_state[0]))
  endif

  return [model, ['cmd.batch', cmds]]
endfu

fu! s:PatternInput.update(msg, model) abort
  let [msg, model] = [a:msg, a:model]

  if msg[0] ==# 'CmdlineChanged'
    if len(msg[1]) < model.esearch.live_update_min_len
      return [extend(model, {'executed_cmdline': msg[1]}), ['cmd.none']]
    endif

    return [extend(model, {'executed_cmdline': msg[1]}), s:force_exec_cmd(model, msg[1])]
  elseif msg[0] ==# 'LiveExecuted'
    let esearch = extend(model.esearch, {'live_update_bufnr': msg[1].bufnr})
    return [extend(model, {'esearch': esearch}), ['cmd.none']]
  elseif msg[0] ==# 'KeyPressed'
    if msg[1] ==# 'main_menu'
      return [model, ['cmd.route', ['main_menu']]]
    else
      return s:cycle_mode(msg, model)
    endif
  elseif msg[0] ==# 'SetCmdline'
    let session = extend(model.session, {'pattern_state': msg[1:]})
    return [extend(model, {'session': session}), ['cmd.none']]
  elseif msg[0] ==# 'Submit'
    let force_exec_cmd = s:force_exec_cmd(model, msg[1])
    if !empty(msg[1]) | call model.esearch.pattern.push(msg[1]) | endif
    return [model, ['cmd.batch', [force_exec_cmd, ['cmd.quit']]]]
  elseif msg[0] ==# 'PushPattern'
    if !model.esearch._adapter.multi_pattern
      return [model, ['cmd.none']]
    endif
    let [cmdline, _] = model.session.pattern_state

    if empty(cmdline)
      call model.esearch.pattern.kinds.next()
    else
      call model.esearch.pattern.push(cmdline)
    endif

    return [extend(model, {'esearch': model.esearch, 'session': extend(model.session, {'pattern_state': ['', -1]})}), ['cmd.none']]
  elseif msg[0] ==# 'PopPattern'
    let popped = model.esearch.pattern.try_pop()
    if empty(popped)
      let session = extend(model.session, {'pattern_state': ['', -1]})
    else
      let session = extend(model.session, {'pattern_state': [popped.str, -1]})
    endif
    return [extend(model, {'esearch': model.esearch, 'session': session}), ['cmd.none']]
  elseif msg[0] ==# 'SelectDisabled'
    let session = extend(model.session, {'pattern_input_select': 0})
    return [extend(model, {'session': session}), ['cmd.none']]
  elseif msg[0] ==# 'Interrupt'
    return [extend(model, {'cmdline': '', 'cmdpos': -1}), ['cmd.quit']]
  else
    throw 'unexpected msg '.string(msg)
  endif
endfu

fu! s:PatternInput.view(model) abort
  let [prompt_chunks, prompt_cmd] = a:model.prompt.view(a:model.prompt)
  let [conf_chunks, configurations_cmd] = a:model.configurations_prompt.view(a:model.configurations_prompt)
  " let statusline_cmd = empty(conf_chunks) ? ['cmd.none'] : ['cmd.statusline', conf_chunks]
  let statusline_cmd = empty(conf_chunks) ? ['cmd.none'] : ['cmd.statusline', conf_chunks]


  " let statusline_cmd = ['cmd.statusline', conf_chunks]
  let getline_cmd = ['cmd.getline', {
        \ 'prompt':      prompt_chunks,
        \ 'cmdline':     a:model.session.pattern_state,
        \ 'preselect':   a:model.session.pattern_input_select,
        \ 'keymaps':     a:model.keymaps,
        \ 'multiple':    1,
        \ 'onset':       'SetCmdline',
        \ 'onpop':       'PopPattern',
        \ 'onunselect':  'SelectDisabled',
        \ 'onsubmit':    'Submit',
        \ 'oninterrupt': 'Interrupt',
        \}]

  return [[], ['cmd.batch', [prompt_cmd, configurations_cmd, statusline_cmd, getline_cmd]]]
endfu

fu! s:force_exec_cmd(model, str) abort
  if empty(a:str) | return ['cmd.none'] | endif
  let esearch = copy(a:model.esearch)
  let esearch.pattern = deepcopy(esearch.pattern)
  call esearch.pattern.push(a:str)
  return ['cmd.force_exec', esearch]
endfu

fu! s:cycle_mode(msg, model) abort
  let esearch = esearch#ui#util#cycle_mode(a:model.esearch, a:msg[1])
  let [prompt, cmd] = a:model.prompt.update(a:msg, a:model.prompt)
  let model = extend(a:model, {'prompt': prompt, 'esearch': esearch})

  let esearch = copy(esearch)
  let esearch.pattern = deepcopy(esearch.pattern)
  call esearch.pattern.add(a:model.session.pattern_state[0])
  let refresh_cmd = ['cmd.force_exec', esearch]

  return [model, ['cmd.batch', [cmd, refresh_cmd]]]
endfu

fu! esearch#ui#locations#pattern_input#import() abort
  return s:PatternInput
endfu
