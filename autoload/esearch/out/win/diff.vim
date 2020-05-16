fu! esearch#out#win#diff#do(parsed_contexts, original_contexts) abort
  let diff = {
        \   'contexts':   {},
        \   'statistics': {
        \     'deleted':  0,
        \     'modified': 0,
        \     'files':    0,
        \   },
        \ }

  for ctx in a:original_contexts
    let diff.contexts[ctx.id] = {
          \ 'original': ctx,
          \ 'filename': ctx.filename,
          \ 'modified': {},
          \ 'deleted': [],
          \ }
    let escaped_filename = fnameescape(ctx.filename)

    " entire context is removed
    if !has_key(a:parsed_contexts, escaped_filename)
      let diff.contexts[ctx.id].deleted = keys(ctx.lines)
      let diff.statistics.files += 1
      let diff.statistics.deleted += len(ctx.lines)
      continue
    endif

    let parsed_ctx = a:parsed_contexts[escaped_filename]
    for [line, text] in items(ctx.lines)
      if has_key(parsed_ctx, line)
        if parsed_ctx[line] !=# text
          let diff.contexts[ctx.id].modified[line] = parsed_ctx[line]
          let diff.statistics.modified += 1
        endif
      else
        call add(diff.contexts[ctx.id].deleted, line)
        let diff.statistics.deleted += 1
      endif
    endfor

    if empty(diff.contexts[ctx.id].modified) && empty(diff.contexts[ctx.id].deleted)
      call remove(diff.contexts, ctx.id)
    else
      let diff.statistics.files += 1
    endif
  endfor

  return diff
endfu
