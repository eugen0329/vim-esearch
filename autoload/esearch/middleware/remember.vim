fu! esearch#middleware#remember#apply(esearch) abort
  " TODO add 'remember' option to handle memoization below
  let g:esearch.last_pattern    = a:esearch.pattern
  let g:esearch.case            = a:esearch.case
  let g:esearch.textobj         = a:esearch.textobj
  let g:esearch.regex           = a:esearch.regex
  let g:esearch.before          = a:esearch.before
  let g:esearch.after           = a:esearch.after
  let g:esearch.context         = a:esearch.context
  let g:esearch.paths           = a:esearch.paths
  let g:esearch.adapters        = a:esearch.adapters
  let g:esearch.current_adapter = a:esearch.current_adapter

  return a:esearch
endfu
