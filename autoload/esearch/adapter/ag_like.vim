let esearch#adapter#ag_like#format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

fu! esearch#adapter#ag_like#joined_paths(esearch) abort
  if empty(a:esearch.paths)
    let joined_paths = a:esearch.cwd
  else
    let joined_paths = esearch#shell#fnamesescape_and_join(a:esearch.paths, a:esearch.metadata)
  endif

  return joined_paths
endfu
