fu! esearch#middleware#map#apply(esearch) abort
  if has_key(a:esearch, 'win_map')
    let a:esearch.win_map = g:esearch.win_map + a:esearch.win_map
  endif

  return a:esearch
endfu
