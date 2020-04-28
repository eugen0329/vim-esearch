let s:Filepath = vital#esearch#import('System.Filepath')

let g:esearch#middleware#filer#filetype2filer = {
      \ 'defx':      'defx',
      \ 'nerdtree':  'nerdtree',
      \ 'dirvish':   'dirvish',
      \ 'netranger': 'netranger',
      \ }

fu! esearch#middleware#filer#apply(esearch) abort
  if !has_key(g:esearch#middleware#filer#filetype2filer, &filetype)
    return a:esearch
  endif

  let filer = s:filer()
  let cwd = esearch#win#lcd(a:esearch.cwd)
  try
    if get(a:esearch, 'visualmode', 0)
      let a:esearch.paths = s:visually_selected_paths(filer)
      let a:esearch.visualmode = 0
    else
      let path = s:to_esearch_path(filer.nearest_directory_path())
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

fu! s:visually_selected_paths(filer) abort
  let paths = a:filer.paths_in_range(getpos("'<")[1], getpos("'>")[1])
  return map(paths, 's:to_esearch_path(v:val)')
endfu

fu! s:filer() abort
  let filer_name = g:esearch#middleware#filer#filetype2filer[&filetype]
  return esearch#compat#filer#{filer_name}#import()
endfu

" Paths are truncated to be relative to imitate that they are inputted manually in
" the shortest way.
" Vital relpath converts home to ~. It cause problems with vim's builtin
" isdirectory(), so fnamemodify is used.
fu! s:to_esearch_path(path) abort
  if s:Filepath.is_relative(a:path)
    return esearch#shell#path(a:path)
  endif

  return esearch#shell#path(fnamemodify(a:path, ':.'))
endfu
