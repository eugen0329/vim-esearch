fu! esearch#adapter#grep_like#joined_paths(esearch) abort
  if empty(a:esearch.paths)
    return ''
  endif

  let paths = deepcopy(a:esearch.paths)
  let escaped = []
  for i in range(0, len(paths)-1)
    call add(escaped, fnameescape(paths[i]))
  endfor

  return join(escaped, ' ')
endfu
