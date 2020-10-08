let s:is_predicate = vital#esearch#import('Vim.Type').is_predicate

fu! esearch#middleware#remember#apply(esearch) abort
  if !empty(a:esearch.remember)
    if s:is_predicate(a:esearch.remember)
      let remember = g:esearch.remember
    else
      let remember = a:esearch.remember
    endif
    for c in remember
      let g:esearch[c] = a:esearch[c]
    endfor
  endif

  return a:esearch
endfu
