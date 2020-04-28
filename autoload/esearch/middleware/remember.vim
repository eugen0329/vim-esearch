fu! esearch#middleware#remember#apply(esearch) abort
  if !empty(a:esearch.remember)
    for config in a:esearch.remember
      let g:esearch[config] = a:esearch[config]
    endfor
  endif

  return a:esearch
endfu
