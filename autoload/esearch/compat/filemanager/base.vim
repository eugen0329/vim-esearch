let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#base#import() abort
  return s:Base
endfu

let s:Base = {}

fu! s:Base.paths_in_range(begin, end) abort
  let paths = []

  let view = winsaveview()
  try
    for line in range(a:begin, a:end)
      call cursor(line, 0)
      let paths += [self.path_under_cursor()]
    endfor
  finally
    call winrestview(view)
  endtry

  return paths
endfu

fu! s:Base.nearest_directory_path() abort
  let path = self.path_under_cursor()

  if isdirectory(path)
    return path
  endif

  return s:Filepath.dirname(path)
endfu
