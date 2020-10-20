fu! esearch#out#win#fold#close() abort
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, b:esearch.state)
  let ctx = contexts.by_line(line('.'))
  if ctx.id == 0
    return
  endif

  if ctx.rev
    let hash = split(ctx.filename, ':')[0]

    let [first, above] = [ctx, ctx]
    while 1
      let above = contexts.by_line(first._begin - 1)
      if above.id ==# 0 || !above.rev || split(above.filename, ':')[0] !=# hash | break | endif
      let first = above
    endw

    let [last, below] = [ctx, ctx]
    while 1
      let below = contexts.by_line(last._end + 1)
      if !below.rev || split(below.filename, ':')[0] !=# hash | break | endif
      let last = below
    endw
  else
    let [first, last] = [ctx, ctx]
  endif

  return first._begin.'GV'.last._end.'Gzf'
endfu

fu! esearch#out#win#fold#close_all() abort
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, b:esearch.state)

  norm! zE
  let wlnum = contexts.by_line(1)._end + 1
  while wlnum < line('$')
    let first = contexts.by_line(wlnum)

    if first.rev
      let hash = split(first.filename, ':')[0]

      let [last, below] = [first, first]
      while 1
        let below = contexts.by_line(last._end + 1)
        if !below.rev || split(below.filename, ':')[0] !=# hash | break | endif
        let last = below
      endw
    else
      let last = first
    endif

    keepjumps exe 'norm! '.first._begin.'GV'.last._end.'Gzf'
    let wlnum = last._end + 1
  endw
endfu

fu! esearch#out#win#fold#text() abort
  let ctx1 = b:esearch.contexts[b:esearch.state[v:foldstart]]
  let ctx2 = b:esearch.contexts[b:esearch.state[v:foldend]]
  if ctx1.id == ctx2.id
    let lines_count = len(ctx1.lines)
    return getline(v:foldstart) . ' ' . lines_count . (lines_count == 1 ? ' line' : ' lines')
  else
    let files_count = ctx2.id - ctx1.id + 1
    return getline(v:foldstart) . ', ... ' .  files_count . ' files'
  endif
endfu
