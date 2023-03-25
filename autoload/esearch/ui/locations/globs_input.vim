let s:LiveUpdate = esearch#ui#context#live_update#import()
let s:Previewable = esearch#ui#context#previewable#import()
let s:GlobsInputPrompt = esearch#ui#components#globs_input_prompt#import()
let s:GlobsInput = {}

cnoremap <expr><plug>(esearch-push-glob) esearch#ui#runtime#onpress(['PushGlob'])
cnoremap <expr><plug>(esearch-next-glob) esearch#ui#runtime#onpress(['NextGlob'])
let s:keymaps = [
      \ ['c', '<c-p>', '<plug>(esearch-push-glob)'],
      \ ['c', '<c-n>', '<plug>(esearch-next-glob)'],
      \]

fu! s:GlobsInput.init(esearch, session) abort
  let kwargs = get(a:session.route, 1, {})

  if get(kwargs, 'push', 0)
    let glob = a:esearch.globs.make('')
  else
    let glob = a:esearch.globs.remove(get(kwargs, 'i', -1))
    call a:esearch.globs.kinds.seek(glob.kind)
  endif

  let cmdpos = get(kwargs, 'cmdpos', -1)
  let model = extend(copy(self), {
        \ 'keymaps': s:keymaps,
        \ 'esearch': a:esearch,
        \ 'glob': glob,
        \ 'session': extend(a:session, {'globs_state': [glob.str, cmdpos]}),
        \ 'globs_input_prompt': s:GlobsInputPrompt.init(a:esearch),
        \})

  return [model, ['cmd.batch', [
        \ ['cmd.context', s:LiveUpdate.new(model, 'CmdlineChanged')],
        \ ['cmd.context', s:Previewable.new()],
        \]]]
endfu

fu! s:GlobsInput.update(msg, model) abort
  if a:msg[0] ==# 'CmdlineChanged'
    let pattern_text = a:model.session.pattern_state[0]
    if empty(a:msg[1]) | return [a:model, ['cmd.none']] | endif

    let [paths, err] = esearch#shell#split(a:msg[1])
    let esearch = copy(a:model.esearch)
    let esearch = extend(esearch, {'paths': paths})
    let esearch.pattern = deepcopy(esearch.pattern)
    call esearch.pattern.push(a:model.session.pattern_state[0])

    return [a:model, ['cmd.batch', [
          \ ['cmd.shellpreview', esearch._adapter.glob_command(esearch), esearch],
          \ ['cmd.force_exec', esearch]]]]
  elseif a:msg[0] ==# 'SetCmdline'
    let session = extend(a:model.session, {'globs_state': a:msg[1:]})
    return [extend(a:model, {'session': session}), ['cmd.none']]
  elseif a:msg[0] ==# 'Submit'
    if !empty(a:msg[1])
      call a:model.esearch.globs.push(a:msg[1])
    endif
    let session = extend(a:model.session, {'globs_state': ['', -1]})

    return [extend(a:model, {'esearch': a:model.esearch, 'session': session}), ['cmd.route', ['main_menu']]]
  elseif a:msg[0] ==# 'NextGlob'
    call a:model.esearch.globs.kinds.next()
    return [a:model, ['cmd.none']]
  elseif a:msg[0] ==# 'PushGlob'
    let [cmdline, _] = a:model.session.globs_state

    if empty(cmdline)
      call a:model.esearch.globs.kinds.next()
    else
      call a:model.esearch.globs.push(cmdline)
    endif

    return [extend(a:model, {'esearch': a:model.esearch, 'session': extend(a:model.session, {'globs_state': ['', -1]})}), ['cmd.none']]
  elseif a:msg[0] ==# 'PopGlob'
    let glob = a:model.esearch.globs.try_pop()
    return [extend(a:model, {
          \ 'esearch': a:model.esearch,
          \ 'session': extend(a:model.session, {'globs_state': [glob.str, -1]}),
          \ }), ['cmd.none']]
  elseif a:msg[0] ==# 'SelectDisabled'
    return [a:model, ['cmd.none']]
  elseif a:msg[0] ==# 'Interrupt'
    if !empty(a:model.session.globs_state[0])
      call a:model.esearch.globs.push(a:msg[1])
    endif
    let route_cmd = ['cmd.route', [empty(a:model.esearch.globs.list) ? 'main_menu' : 'globs_menu']]
    " TODO test case
    return [extend(a:model, {'session': extend(a:model.session, {'globs_state': [a:model.esearch.globs.peek().str, -1]}, 'force')}), route_cmd]
  else
    if a:msg[0] ==# 'SelectMode'
      return s:cycle_mode(a:msg, a:model)
    endif
  endif

  throw 'unexpected msg '.string(a:msg)
endfu

fu! s:GlobsInput.view(model) abort
  let [prompt_chunks, prompt_cmd]  = a:model.globs_input_prompt.view(a:model.globs_input_prompt)
  let ellipsis = g:esearch#has#unicode ? g:esearch#unicode#ellipsis : '...'
  let prompt_chunks = [[a:model.esearch.adapter.' '.ellipsis.' ', 'None']] + prompt_chunks

  return [[], ['cmd.getline', {
        \ 'preselect':   0,
        \ 'multiple':    1,
        \ 'prompt':      prompt_chunks,
        \ 'cmdline':     a:model.session.globs_state,
        \ 'keymaps':     a:model.keymaps,
        \ 'onset':       'SetCmdline',
        \ 'onpop':       'PopGlob',
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

fu! esearch#ui#locations#globs_input#import() abort
  return s:GlobsInput
endfu
