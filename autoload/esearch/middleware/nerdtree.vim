let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#middleware#nerdtree#apply(esearch) abort
  if !a:esearch.nerdtree_plugin || &filetype !=# 'nerdtree'
    return a:esearch
  endif

  let cwd = esearch#win#lcd(a:esearch.cwd)
  try
    if get(a:esearch, 'visualmode', 0)
      let a:esearch.paths = s:visually_selected_paths()
      let a:esearch.visualmode = 0
    else
      let path = s:nearest_directory_path()
      if s:Filepath.relpath(path.str) ==# s:Filepath.relpath(a:esearch.cwd)
        let a:esearch.paths = []
      else
        let a:esearch.paths = [path]
      endif
    endif
  finally
    call cwd.restore()
  endtry

  return a:esearch
endfu

fu! s:visually_selected_paths() abort
  let begin = getpos("'<")[1]
  let end   = getpos("'>")[1]
  let paths = []

  let view = winsaveview()
  try
    for line in range(begin, end)
      call cursor(line, 0)
      let path = g:NERDTreeFileNode.GetSelected().path
      let paths += [s:to_esearch_path(path)]
    endfor
  finally
    call winrestview(view)
  endtry

  return paths
endfu

fu! s:nearest_directory_path() abort
  let path = g:NERDTreeFileNode.GetSelected().path
  return s:to_esearch_path(path.isDirectory ? path : path.getParent())
endfu

" Paths are truncated to be relative to imitate that they are inputted manually in
" the shortest way.
" Vital relpath converts home to ~. It cause problems with vim's builtin
" isdirectory(), so fnamemodify is used.
fu! s:to_esearch_path(nerdtree_path) abort
  let path = a:nerdtree_path.str({'escape': 0})
  let path = s:Filepath.is_relative(path) ? path : fnamemodify(path, ':.')
  return esearch#shell#path(path)
endfu
