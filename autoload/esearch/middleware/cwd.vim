let s:Prelude  = vital#esearch#import('Prelude')

fu! esearch#middleware#cwd#apply(esearch) abort
  if !has_key(a:esearch, 'cwd')
    let a:esearch.cwd = esearch#middleware#cwd#_find_root(getcwd(), a:esearch.root_markers)
  endif

  return a:esearch
endfu
"
" TODO coverage
fu! esearch#middleware#cwd#_find_root(path, markers) abort
  " Partially based on vital's prelude path2project-root internals
  let start_dir = s:Prelude.path2directory(a:path)
  " TODO rewrite to return start_dir when ticket with fixing cwd handling is
  " ready
  if empty(a:markers) | return a:path | endif

  let dir = start_dir
  let max_depth = 50
  let depth = 0

  while depth < max_depth
    for marker in a:markers
      let file = globpath(dir, marker, 1)

      if file !=# ''
        return s:Prelude.substitute_path_separator(fnamemodify(file, ':h'))
      endif
    endfor

    let dir_upwards = fnamemodify(dir, ':h')
    " if it's fs root - use start_dir
    if dir_upwards == dir
      return start_dir
    endif
    let dir = dir_upwards
    let depth += 1
  endwhile

  return start_dir
endfu
