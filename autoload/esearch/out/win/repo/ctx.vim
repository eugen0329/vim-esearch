fu! esearch#out#win#repo#ctx#new(esearch, state) abort
  return {
        \ 'esearch':      a:esearch,
        \ 'state':        a:state,
        \ 'by_line':      function('<SID>by_line'),
        \ }
endfu

fu! s:by_line(line) abort dict
  let line = a:line
  if len(self.state.context_ids_map) <= line
    return 0
  endif

  let context = self.esearch.contexts[self.state.context_ids_map[line]]

  " read-through cache synchronization
  let context.begin = s:line_begin(self.state.context_ids_map, context, line)
  let context.end   = s:line_end(self.state.context_ids_map, context, line)

  return context
endfu

fu! s:line_begin(context_ids_map, context, line) abort
  let line = a:line
  let context_ids_map = a:context_ids_map

  while line > 0
    if context_ids_map[line - 1] !=# a:context.id
      return line
    endif

    let line -= 1
  endwhile

  return 1
endfu

fu! s:line_end(context_ids_map, context, line) abort
  let line = a:line
  let context_ids_map = a:context_ids_map

  while line < len(context_ids_map) - 1
    if context_ids_map[line + 1] !=# a:context.id
      return line
    endif

    let line += 1
  endwhile

  return len(context_ids_map) - 1
  throw "Can't find context begin: " . string([a:context, a:line])
endfu
