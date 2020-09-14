fu! esearch#out#win#diff#do(parsed, esearch) abort
  let theirs_ctx_by_name = a:parsed.ctx_by_name

  let diffs = {
        \  'by_id': {},
        \  'stats': {
        \    'deleted':  0,
        \    'modified': 0,
        \    'added': 0,
        \    'files':    0,
        \  },
        \}

  for ours_ctx in b:esearch.contexts[1:]
    let edits = []

    let filename = fnameescape(ours_ctx.filename)
    if !has_key(theirs_ctx_by_name, filename)
      let diffs.stats.files += 1
      let diffs.stats.deleted += len(ours_ctx.lines)
      let edits = map(keys(ours_ctx.lines), "{'func': 'deleteline', 'args': [v:val], 'lnum': v:val}")
      let diffs.by_id[ours_ctx.id] = {'ctx': ours_ctx, 'edits': edits}
      continue
    endif

    let theirs_lines = theirs_ctx_by_name[filename].lines
    for [lnum, text] in items(ours_ctx.lines)
      if has_key(theirs_lines, lnum)
        if len(theirs_lines[lnum]) > 1 || theirs_lines[lnum][0] !=# text
          call add(edits, {'func': 'setlines', 'args': [lnum, theirs_lines[lnum]], 'lnum': lnum})
          let diffs.stats.modified += len(theirs_lines[lnum])
        endif
        call remove(theirs_lines, lnum)
      else
        call add(edits, {'func': 'deleteline', 'args': [lnum], 'lnum': lnum})
        let diffs.stats.deleted += 1
      endif
    endfor

    for [lnum, texts] in items(theirs_lines)
      call add(edits, {'func': 'append', 'args': [lnum-1, texts], 'lnum': lnum})
      let diffs.stats.added += len(texts)
    endfor

    if !empty(edits)
      let diffs.stats.files += 1
      call sort(edits, { val -> -val.args[0] })
      let diffs.by_id[ours_ctx.id] = {'ctx': ours_ctx, 'edits': edits}
    endif
  endfor

  return diffs
endfu
