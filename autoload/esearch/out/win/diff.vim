fu! esearch#out#win#diff#do(parsed_contexts, original_contexts) abort
  let diff = {
        \   'files': {},
        \   'statistics': {
        \     'deleted': 0,
        \     'modified': 0,
        \     'files': 0,
        \   },
        \ }

  for [filename, original] in items(a:original_contexts)
    if has_key(a:parsed_contexts, filename)
      let parsed = a:parsed_contexts[filename]
      let diff.files[filename] = {'modified': {}, 'deleted': []}

      for [line, text] in items(original.lines)
        if has_key(parsed, line)
          " TODO test case match
          if parsed[line] !=# text
            let diff.files[filename].modified[line] = parsed[line]
            let diff.statistics.modified += 1
          endif
        else
          call add(diff.files[filename].deleted, line)
          let diff.statistics.deleted += 1
        endif
      endfor

      if empty(diff.files[filename].modified) && empty(diff.files[filename].deleted)
        call remove(diff.files, filename)
      else
        let diff.statistics.files += 1
      endif
    else
      let diff.files[filename] = {'deleted': keys(original.lines)}
      let diff.statistics.files += 1
      let diff.statistics.deleted += len(original.lines)
    endif
  endfor

  return diff
endfu
