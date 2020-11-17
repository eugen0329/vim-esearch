fu! esearch#middleware#splice_pattern#apply(esearch) abort
  call a:esearch.pattern.splice(a:esearch)
  let a:esearch.last_pattern = a:esearch.pattern
  return a:esearch
endfu
