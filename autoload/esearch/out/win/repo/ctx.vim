fu! esearch#out#win#repo#ctx#new(esearch, state) abort
  return {
        \ 'esearch': a:esearch,
        \ 'state':   a:state,
        \ 'by_line': function('<SID>by_line'),
        \ }
endfu

fu! s:by_line(line) abort dict
  let line = a:line
  if len(self.state.ctx_ids_map) <= line
    return 0
  endif
  let ctx = self.esearch.contexts[self.state.ctx_ids_map[line]]

  " read-through cache synchronization
  let ctx.begin = s:line_begin(self.state.ctx_ids_map, ctx, line)
  let ctx.end   = s:line_end(self.state.ctx_ids_map, ctx, line)

  return ctx
endfu

fu! s:line_begin(ctx_ids_map, ctx, line) abort
  let line = a:line
  let ctx_ids_map = a:ctx_ids_map

  while line > 0
    if ctx_ids_map[line - 1] !=# a:ctx.id
      return line
    endif

    let line -= 1
  endwhile

  return 1
endfu

fu! s:line_end(ctx_ids_map, ctx, line) abort
  let line = a:line
  let ctx_ids_map = a:ctx_ids_map

  while line < len(ctx_ids_map) - 1
    if ctx_ids_map[line + 1] !=# a:ctx.id
      return line
    endif

    let line += 1
  endwhile

  return len(ctx_ids_map) - 1
  throw "Can't find ctx begin: " . string([a:ctx, a:line])
endfu
