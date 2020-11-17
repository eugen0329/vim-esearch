let s:Filepath = vital#esearch#import('System.Filepath')

let g:esearch#middleware#filemanager#filetype2filer = {
      \ 'defx':      'defx',
      \ 'fern':      'fern',
      \ 'nerdtree':  'nerdtree',
      \ 'dirvish':   'dirvish',
      \ 'netranger': 'netranger',
      \ }

fu! esearch#middleware#filemanager#apply(esearch) abort
  if !has_key(g:esearch#middleware#filemanager#filetype2filer, &filetype)
        \ || !a:esearch.filemanager_integration
        \ || (a:esearch.live_update && a:esearch.force_exec)
    return a:esearch
  endif

  let filer = s:filer()
  let cwd = esearch#win#lcd(a:esearch.cwd)
  try
    if empty(get(a:esearch, 'region'))
      let paths = esearch#shell#argv(filer.nearest_dir_or_selected_nodes())
      if paths ==# esearch#shell#argv([a:esearch.cwd])
         let paths = esearch#shell#argv([])
      endif
    else
      let paths = s:paths_in_range(filer, a:esearch.region)
      call remove(a:esearch, 'region')
      let a:esearch.force_exec = 0
    endif

    " TODO implement a:esearch.paths to work like an object
    if type(a:esearch.paths) == type({})
      let a:esearch.paths.pathspec = paths
    else
      let a:esearch.paths = paths
    endif
  finally
    call cwd.restore()
  endtry

  return a:esearch
endfu

fu! s:paths_in_range(filer, region) abort
  let [begin, end] = esearch#operator#range(a:region)
  let paths = a:filer.paths_in_range(line(begin), line(end))
  return esearch#shell#argv(paths)
endfu

fu! s:filer() abort
  let filer_name = g:esearch#middleware#filemanager#filetype2filer[&filetype]
  return esearch#compat#filemanager#{filer_name}#import()
endfu
