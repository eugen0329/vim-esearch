let s:Filepath = vital#esearch#import('System.Filepath')

let g:esearch#middleware#filemanager#filetype2filer = {
      \ 'defx':      'defx',
      \ 'nerdtree':  'nerdtree',
      \ 'dirvish':   'dirvish',
      \ 'netranger': 'netranger',
      \ }

fu! esearch#middleware#filemanager#apply(esearch) abort
  if !has_key(g:esearch#middleware#filemanager#filetype2filer, &filetype) || !a:esearch.filemanager_integration
    return a:esearch
  endif

  let filer = s:filer()
  let cwd = esearch#win#lcd(a:esearch.cwd)
  try
    if empty(get(a:esearch, 'region'))
      let path = s:to_esearch_path(filer.nearest_directory_path())
      if s:Filepath.relpath(path.str) ==# s:Filepath.relpath(a:esearch.cwd)
        let a:esearch.paths = []
      else
        let a:esearch.paths = [path]
      endif
    else
      let a:esearch.paths = s:paths_in_region(filer, a:esearch.region)
      call remove(a:esearch, 'region')
    endif
  finally
    call cwd.restore()
  endtry
  let a:esearch.remember = filter(copy(a:esearch.remember), 'v:val !=# "paths"')

  return a:esearch
endfu

fu! s:paths_in_region(filer, region) abort
  let paths = a:filer.paths_in_range(line(a:region.begin), line(a:region.end))
  return map(paths, 's:to_esearch_path(v:val)')
endfu

fu! s:filer() abort
  let filer_name = g:esearch#middleware#filemanager#filetype2filer[&filetype]
  return esearch#compat#filemanager#{filer_name}#import()
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
