let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filer#dirvish#import() abort
  return s:Dirvish
endfu

let s:Dirvish = copy(esearch#compat#filer#base#import())

fu! s:Dirvish.nearest_directory_path()
  let path = getline('.')

  if isdirectory(path)
    return path
  endif

  return s:Filepath.dirname(path)
endfu

fu! s:Dirvish.path_under_cursor()
  return getline('.')
endfu

fu! s:Dirvish.paths_in_range(begin, end) abort
  return getline(a:begin, a:end)
endfu
