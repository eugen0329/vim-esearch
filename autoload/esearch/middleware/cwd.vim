let s:Prelude  = vital#esearch#import('Prelude')

fu! esearch#middleware#cwd#apply(esearch) abort
  if has_key(a:esearch, 'cwd')
    if !empty(a:esearch.cwd) && !isdirectory(a:esearch.cwd)
      call esearch#util#warn('esearch: directory '.a:esearch.cwd." doesn't exist")
      throw 'Cancel'
    endif

    return a:esearch
  endif

  let root = esearch#util#find_up(getcwd(), a:esearch.root_markers)
  let a:esearch.cwd = empty(root) ? getcwd() : s:Prelude.substitute_path_separator(fnamemodify(root, ':h'))
  return a:esearch
endfu
