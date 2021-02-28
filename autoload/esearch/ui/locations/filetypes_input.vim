let s:Dict  = vital#esearch#import('Data.Dict')
let s:keymaps = []
let s:LiveUpdate = esearch#ui#context#live_update#import()
let s:FiletypesInput = {}
let s:highlight = ['esearch#ui#highlight#words', {
      \ 're':   '\S\+',
      \ 'word': { word -> get(s:filetype_hl, word, 'Comment') },
      \ 'err':  { word -> word =~# '\W' ? 'Error' : 0         },
      \}]

fu! s:FiletypesInput.init(esearch, session) abort
  let s:filetypes = a:esearch._adapter.filetypes
  let s:filetype_hl = s:Dict.make_index(s:filetypes, 'Typedef')

  let filetypes_state = [a:esearch.filetypes, -1]

  let model = extend(copy(self), {
        \ 'keymaps': s:keymaps,
        \ 'esearch': a:esearch,
        \ 'session': extend(a:session, {'filetypes_state': filetypes_state}, 'keep'),
        \ })

  return [model, ['cmd.batch', [
        \ ['cmd.context', s:LiveUpdate.new(model, 'CmdlineChanged')],
        \]]]
endfu

fu! s:FiletypesInput.update(msg, model) abort
  if a:msg[0] ==# 'CmdlineChanged'
    " TODO sideeffect
    let pattern_text = a:model.session.pattern_state[0]
    if empty(a:msg[1]) || empty(pattern_text) | return [a:model, ['cmd.none']] | endif

    let esearch = copy(a:model.esearch)
    let esearch = extend(esearch, {'filetypes': a:msg[1]})
    let esearch.pattern = deepcopy(esearch.pattern)
    call esearch.pattern.add(a:model.session.pattern_state[0])

    return [a:model, ['cmd.force_exec', esearch]]
  elseif a:msg[0] ==# 'SetCmdline'
    let session = extend(a:model.session, {'filetypes_state': a:msg[1:]})
    return [extend(a:model, {'session': session}), ['cmd.none']]
  elseif a:msg[0] ==# 'Submit'
    let session = extend(a:model.session, {'filetypes_state': a:msg[1:]})
    let esearch = extend(a:model.esearch, {'filetypes': a:msg[1]})
    return [extend(a:model, {'esearch': esearch, 'session': session}), ['cmd.route', ['main_menu']]]
  elseif a:msg[0] ==# 'SelectDisabled'
    return [a:model, ['cmd.none']]
  elseif a:msg[0] ==# 'Interrupt'
    " TODO test case
    return [extend(a:model, {'session': extend(a:model.session, {'filetypes_state': [a:model.esearch.filetypes, -1]})}), ['cmd.route', ['main_menu']]]
  else
    throw 'unexpected msg '.string(a:msg)
  endif
endfu

fu! s:FiletypesInput.view(model) abort
  return [[], ['cmd.getline', {
        \ 'preselect':   1,
        \ 'prompt':      [['[filetypes] > ', 'None']],
        \ 'cmdline':     a:model.session.filetypes_state,
        \ 'keymaps':     a:model.keymaps,
        \ 'completion':  'customlist,esearch#ui#locations#filetypes_input#completion',
        \ 'highlight':   s:highlight,
        \ 'onset':       'SetCmdline',
        \ 'onunselect':  'SelectDisabled',
        \ 'onsubmit':    'Submit',
        \ 'oninterrupt': 'Interrupt',
        \}]]
endfu

fu! esearch#ui#locations#filetypes_input#completion(arglead, cmdline, curpos) abort
  return esearch#ui#complete#filetypes#do(s:filetypes, a:arglead, a:cmdline, a:curpos)
endfu

fu! esearch#ui#locations#filetypes_input#import() abort
  return s:FiletypesInput
endfu
