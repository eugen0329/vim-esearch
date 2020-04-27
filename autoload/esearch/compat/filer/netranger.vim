let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filer#netranger#import() abort
  return s:NETRanger
endfu

let s:NETRanger = copy(esearch#compat#filer#base#import())

fu! s:NETRanger.nearest_directory_path()
  let path = netranger#cur_node_path()

  if isdirectory(path)
    return path
  endif

  return s:Filepath.dirname(path)
endfu

fu! s:NETRanger.path_under_cursor()
  return netranger#cur_node_path()
endfu

fu! s:NETRanger.paths_in_range(begin, end) abort
  let paths = []

  let view = winsaveview()
  try
    for line in range(a:begin, a:end)
      call cursor(line, 0)
      call esearch#util#doautocmd('CursorMoved')
      let path = self.path_under_cursor()
      let paths += [path]
    endfor
  finally
    call winrestview(view)
    call esearch#util#doautocmd('CursorMoved')
  endtry

  return paths
endfu
