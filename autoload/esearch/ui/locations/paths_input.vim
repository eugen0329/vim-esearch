let s:keymaps = []
let s:LiveUpdate = esearch#ui#context#live_update#import()
let s:PathsInput = {}
let s:region_hl = {'`': 'Special', "'": 'String', '"': 'String'}
let s:char_hl = map(copy(g:esearch#shell#is_metachar), '"Identifier"')
let s:err_hl = {'\': 'Error', "'": 'Error', '"': 'Error', '`': 'Error'}
let s:highlight = ['esearch#ui#highlight#words', {
      \ 're':   g:esearch#shell#word_re,
      \ 'word': { word -> get(s:char_hl, word, get(s:region_hl, word[0])) },
      \ 'err':  { word -> get(s:err_hl, word)                             },
      \}]

fu! s:PathsInput.init(esearch, session) abort
  let paths_state = [esearch#shell#join(a:esearch.paths), -1]
  let model = extend(copy(self), {
        \ 'keymaps': s:keymaps,
        \ 'esearch': a:esearch,
        \ 'session': extend(a:session, {'paths_state': paths_state}, 'keep'),
        \ })

  return [model, ['cmd.batch', [
        \ ['cmd.context', s:LiveUpdate.new(model, 'CmdlineChanged')],
        \]]]
endfu

fu! s:PathsInput.update(msg, model) abort
  if a:msg[0] ==# 'CmdlineChanged'
    " TODO sideeffect
    let pattern_text = a:model.session.pattern_state[0]
    if empty(a:msg[1]) || empty(pattern_text) | return [a:model, ['cmd.none']] | endif

    let [paths, err] = esearch#shell#split(a:msg[1])
    let esearch = copy(a:model.esearch)
    let esearch = extend(esearch, {'paths': paths})
    let esearch.pattern = deepcopy(esearch.pattern)
    call esearch.pattern.add(a:model.session.pattern_state[0])

    return [a:model, ['cmd.force_exec', esearch]]
  elseif a:msg[0] ==# 'SetCmdline'
    let session = extend(a:model.session, {'paths_state': a:msg[1:]})
    return [extend(a:model, {'session': session}), ['cmd.none']]
  elseif a:msg[0] ==# 'Submit'
    let [paths, err] = esearch#shell#split(a:msg[1])
    let session = extend(a:model.session, {'paths_state': a:msg[1:]})
    let esearch = extend(a:model.esearch, {'paths': paths})
    return [extend(a:model, {'esearch': esearch, 'session': session}), ['cmd.route', ['main_menu']]]
  elseif a:msg[0] ==# 'SelectDisabled'
    return [a:model, ['cmd.none']]
  elseif a:msg[0] ==# 'Interrupt'
    " TODO test case
    return [extend(a:model, {'session': extend(a:model.session, {'paths_state': [esearch#shell#join(a:model.esearch.paths), -1]}, 'force')}), ['cmd.route', ['main_menu']]]
  else
    if a:msg[0] ==# 'SelectMode'
      return s:cycle_mode(a:msg, a:model)
    endif
    throw 'unexpected msg '.string(a:msg)
  endif
endfu

fu! s:PathsInput.view(model) abort
  return [[], ['cmd.getline', {
        \ 'preselect':   1,
        \ 'prompt':      [['[paths] > ', 'None']],
        \ 'cmdline':     a:model.session.paths_state,
        \ 'keymaps':     a:model.keymaps,
        \ 'highlight':   s:highlight,
        \ 'onset':       'SetCmdline',
        \ 'onunselect':  'SelectDisabled',
        \ 'onsubmit':    'Submit',
        \ 'oninterrupt': 'Interrupt',
        \}]]
endfu

fu! s:cycle_mode(msg, model) abort
  let esearch = esearch#ui#util#cycle_mode(a:model.esearch, a:model.esearch._adapter, a:msg[1])
   let [prompt, cmd] = a:model.prompt.update(a:msg, a:model.prompt)
   return [extend(a:model, {'prompt': prompt, 'esearch': esearch}), cmd]
endfu

fu! esearch#ui#locations#paths_input#import() abort
  return s:PathsInput
endfu
