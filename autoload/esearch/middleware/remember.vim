fu! esearch#middleware#remember#apply(esearch) abort
  if !empty(a:esearch.remember)
    for c in a:esearch.remember
      let g:esearch[c] = a:esearch[c]
    endfor
  endif

  return a:esearch
endfu
