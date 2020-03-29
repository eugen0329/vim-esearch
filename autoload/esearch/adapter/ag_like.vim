let esearch#adapter#ag_like#format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

fu! esearch#adapter#ag_like#joined_paths(esearch) abort
  if empty(a:esearch.paths)
    return ''
  endif

  return esearch#shell#fnamesescape_and_join(a:esearch.paths, a:esearch.metadata)
endfu
