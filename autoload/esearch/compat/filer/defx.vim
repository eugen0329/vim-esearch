let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filer#defx#import() abort
  return s:Defx
endfu

let s:Defx = copy(esearch#compat#filer#base#import())

fu! s:Defx.nearest_directory_path() abort
  let path = defx#get_candidate().action__path

  if isdirectory(path)
    return path
  endif

  return s:Filepath.dirname(path)
endfu

fu! s:Defx.path_under_cursor() abort
  return defx#get_candidate().action__path
endfu
