let s:Filepath = vital#esearch#import('System.Filepath')
let s:List = vital#esearch#import('Data.List')
let s:String = vital#esearch#import('Data.String')
let s:PathsPrompt = esearch#ui#components#paths_prompt#import()
let s:FiletypePrompt = esearch#ui#components#filetypes_prompt#import()
" let s:GlobPrompt = esearch#ui#prompt#glob#import()
let s:ConfigurationsPrompt = {}

fu! s:ConfigurationsPrompt.init(esearch) abort
  let model = extend(copy(self), {
        \ 'esearch': a:esearch,
        \ 'hl': {'normal': 'None'},
        \})

  let cwd = a:esearch.cwd
  let cwd_path = esearch#shell#argv(cwd ==# getcwd() ? [] : [cwd])
  if type(a:esearch.paths) ==# type({})
    let [abspaths, relpaths, xargs] = [[], [], a:esearch.paths]
  else
    let [abspaths, relpaths, xargs] = g:esearch#has#posix_shell
          \ ? s:List.partition(function('s:is_abspath'), a:esearch.paths) + [[]]
          \ : [a:esearch.paths, [], []]
  endif

  call extend(model, {
    \ 'filetypes_prompt': s:FiletypePrompt.init(a:esearch._adapter, a:esearch.filetypes),
    \ 'cwd_prompt':       s:PathsPrompt.init(cwd, cwd_path, [' ', 'None'], model.hl),
    \ 'abspaths_prompt':  s:PathsPrompt.init(cwd, abspaths, [' ', 'None'], model.hl),
    \ 'relpaths_prompt':  s:PathsPrompt.init(cwd, relpaths, [' ', 'None'], model.hl),
    \ 'xargs_prompt':     s:PathsPrompt.init(cwd, xargs,    [' ', 'None'], model.hl),
    \})

  return model
endfu

fu! s:ConfigurationsPrompt.update(msg, model) abort
  return [extend(a:model, {}), ['cmd.none']]
endfu

fu! s:ConfigurationsPrompt.view(model) abort dict
  let groups = []

  let [filetypes_chunks, filetypes_cmd] = a:model.filetypes_prompt.view(a:model.filetypes_prompt)
  call add(groups, filetypes_chunks)
  let [path_chunks, paths_cmds] = s:view_{g:esearch#shell#kind}_paths(a:model)
  call add(groups, path_chunks)

  let chunks = esearch#util#join(groups, [' ', 'None'])
  let chunks = empty(chunks) ? [] : [['In ', a:model.hl.normal]] + chunks

  return [chunks, ['cmd.batch', [filetypes_cmd] + paths_cmds]]
endfu

fu! s:view_posix_paths(model) abort
  let [chunks, cmds] = [[], []]

  let cwd_chunks = []
  if a:model.esearch.cwd !=# getcwd()
    let [cwd_chunks, cwd_cmd] = a:model.cwd_prompt.view(a:model.cwd_prompt)
    let cmds += [cwd_cmd]
  endif

  let sep = empty(cwd_chunks) ? [' ', 'None'] : [', ', 'None']
  let [relpaths_chunks, relpaths_cmd] = a:model.relpaths_prompt.view(a:model.relpaths_prompt, sep)
  let [xargs_chunks, xargs_cmd] = a:model.xargs_prompt.view(a:model.xargs_prompt, sep)
  let [abspaths_chunks, abspaths_cmd] = a:model.abspaths_prompt.view(a:model.abspaths_prompt)

  let relative_chunks = xargs_chunks + relpaths_chunks
  let cmds += [relpaths_cmd, xargs_cmd, abspaths_cmd]

  if empty(cwd_chunks)
    let chunks += relative_chunks
  elseif !empty(relative_chunks)
    let chunks += cwd_chunks + [['/{ ', a:model.hl.normal]] + relative_chunks + [[' }', a:model.hl.normal]]
  endif

  return [chunks + abspaths_chunks, cmds]
endfu

" TODO
fu! s:view_windows_paths(model) abort dict
  let [chunks, cmds] = [[], []]

  let cwd_chunks = []
  if a:model.esearch.cwd !=# getcwd()
    let [cwd_chunks, cwd_cmd] = a:model.cwd_prompt.view(a:model.cwd_prompt)
    let cmds += [cwd_cmd]
  endif
  let [abspaths_chunks, abspaths_cmd] = a:model.abspaths_prompt.view(a:model.abspaths_prompt)
  let cmds += [abspaths_cmd]

  if !empty(cwd_chunks)
    let chunks += [['cwd: ', a:model.hl.normal]] + cwd_chunks + [[', ', a:model.hl.normal]]
  endif
  if !empty(abspaths_chunks)
    let chunks += abspaths_chunks
  endif

  return  + abspaths_chunks
endfu

fu! s:is_abspath(path) abort
  return esearch#util#is_abspath(a:path.str)
endfu

fu! esearch#ui#components#configurations_prompt#import() abort
  return s:ConfigurationsPrompt
endfu
