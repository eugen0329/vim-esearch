fu! esearch#out#win#repo#ctx#new(esearch, state) abort
  return {
        \ 'esearch': a:esearch,
        \ 'state':   a:state,
        \ 'by_line': function('<SID>by_line'),
        \}
endfu

fu! s:by_line(wlnum) abort dict
  let wlnum = a:wlnum
  if len(self.state) <= wlnum
    return g:esearch#out#win#view_data#null_ctx
  endif
  let ctx = self.esearch.contexts[self.state[wlnum]]

  " read-through cache synchronization
  let ctx._begin = s:line_begin(self.state, ctx, wlnum)
  let ctx._end   = s:line_end(self.state, ctx, wlnum)

  return ctx
endfu

fu! s:line_begin(state, ctx, wlnum) abort
  let wlnum = a:wlnum
  let state = a:state

  while wlnum > 0
    if state[wlnum - 1] !=# a:ctx.id
      return wlnum
    endif

    let wlnum -= 1
  endwhile

  return 1
endfu

fu! s:line_end(state, ctx, wlnum) abort
  let wlnum = a:wlnum
  let state = a:state

  while wlnum < len(state) - 1
    if state[wlnum + 1] !=# a:ctx.id
      return wlnum
    endif

    let wlnum += 1
  endwhile

  return len(state) - 1
  throw "Can't find ctx begin: " . string([a:ctx, a:wlnum])
endfu
