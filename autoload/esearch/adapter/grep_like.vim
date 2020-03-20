let esearch#adapter#grep_like#multiple_files_Search_format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

fu! esearch#adapter#grep_like#joined_paths(esearch) abort
  if empty(a:esearch.paths)
    let joined_paths = a:esearch.cwd
  else
    let paths = deepcopy(a:esearch.paths)
    let escaped = []
    for i in range(0, len(paths)-1)
      call add(escaped, fnameescape(paths[i]))
    endfor

    let joined_paths = join(escaped, ' ')
  endif

  return joined_paths
endfu
