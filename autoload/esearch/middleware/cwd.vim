let s:Prelude  = vital#esearch#import('Prelude')

fu! esearch#middleware#cwd#apply(esearch) abort
  if has_key(a:esearch, 'cwd') | return a:esearch | endif

  let root = esearch#util#find_up(getcwd(), a:esearch.root_markers)
  let a:esearch.cwd = empty(root) ? getcwd() : s:Prelude.substitute_path_separator(fnamemodify(root, ':h'))
  return a:esearch
endfu
