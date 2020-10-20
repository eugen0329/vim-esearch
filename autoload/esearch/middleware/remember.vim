fu! esearch#middleware#remember#apply(esearch) abort
  if !empty(a:esearch.remember)
    if type(a:esearch.remember) is# type([])
      let remember = a:esearch.remember
    else
      let remember = g:esearch.remember
    endif
    for c in remember
      let g:esearch[c] = a:esearch[c]
    endfor
  endif

  return a:esearch
endfu
