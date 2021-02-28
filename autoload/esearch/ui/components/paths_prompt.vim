let s:PathsPrompt = {}

fu! s:PathsPrompt.init(cwd, paths, sep, hl) abort
  return extend(copy(self), {
        \ 'cwd': a:cwd,
        \ 'paths': a:paths,
        \ 'hl': a:hl,
        \ 'sep': a:sep,
        \ 'escape': 1,
        \ })
endfu

fu! s:PathsPrompt.update(msg, model) abort
  return [a:model, ['cmd.none']]
endfu

" TODO
fu! s:PathsPrompt.view(model, ...) abort
  if empty(a:model.paths)
    return [[], ['cmd.none']]
  elseif type(a:model.paths) ==# type({})
    return [[[a:model.paths.repr(), 'Special']], ['cmd.none']]
  elseif !g:esearch#has#posix_shell
    return [[[esearch#shell#join(a:model.paths), a:model.hl.normal]], ['cmd.none']]
  endif

  let l:Escape = a:model.escape ? function('esearch#shell#escape') : {path -> path.str}
  let cwd = a:model.cwd
  let paths = a:model.paths
  let chunks = []
  let dir_icon = g:esearch#has#unicode ?  g:esearch#unicode#dir_icon : 'D '
  for i in range(len(paths))
    let path = paths[i]
    if path.meta
      call add(chunks, s:highlight_meta(a:model, path))
    elseif isdirectory(esearch#util#abspath(cwd, path.str))
      call add(chunks, [[dir_icon . l:Escape(path), 'Directory']])
    else
      call add(chunks, [[l:Escape(path), a:model.hl.normal]])
    endif
  endfor

  return [esearch#util#join(chunks, a:0 ? a:1 : a:model.sep), ['cmd.none']]
endfu

fu! s:highlight_meta(model, path) abort
  let chunks = []

  for [meta, text] in a:path.tokens
    if meta
      call add(chunks, [text, text[0] ==# '`' ? 'Special' : 'Identifier'])
    else
      call add(chunks, [fnameescape(text), a:model.hl.normal])
    endif
  endfor

  return chunks
endfu

fu! esearch#ui#components#paths_prompt#import() abort
  return s:PathsPrompt
endfu
