fu! esearch#out#win#repo#ctx#new(esearch, state) abort
  return {
        \ 'esearch': a:esearch,
        \ 'state':   a:state,
        \ 'by_line': function('<SID>by_line'),
        \ }
endfu

fu! s:by_line(line) abort dict
  let line = a:line
  if len(self.state.wlnum2ctx_id) <= line
    return 0
  endif
  let ctx = self.esearch.contexts[self.state.wlnum2ctx_id[line]]

  " read-through cache synchronization
  let ctx._begin = s:line_begin(self.state.wlnum2ctx_id, ctx, line)
  let ctx._end   = s:line_end(self.state.wlnum2ctx_id, ctx, line)

  return ctx
endfu

fu! s:line_begin(wlnum2ctx_id, ctx, line) abort
  let line = a:line
  let wlnum2ctx_id = a:wlnum2ctx_id

  while line > 0
    if wlnum2ctx_id[line - 1] !=# a:ctx.id
      return line
    endif

    let line -= 1
  endwhile

  return 1
endfu

fu! s:line_end(wlnum2ctx_id, ctx, line) abort
  let line = a:line
  let wlnum2ctx_id = a:wlnum2ctx_id

  while line < len(wlnum2ctx_id) - 1
    if wlnum2ctx_id[line + 1] !=# a:ctx.id
      return line
    endif

    let line += 1
  endwhile

  return len(wlnum2ctx_id) - 1
  throw "Can't find ctx begin: " . string([a:ctx, a:line])
endfu
