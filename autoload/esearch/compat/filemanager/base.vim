let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#base#import() abort
  return copy(s:Base)
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

fu! s:Base.nearest_dir_or_selected_nodes() abort
  let path = self.path_under_cursor()
  return isdirectory(path) ? [path] : [s:Filepath.dirname(path)]
endfu
