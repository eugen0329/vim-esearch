let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#netranger#import() abort
  return s:NETRanger
endfu

let s:NETRanger = esearch#compat#filemanager#base#import()

fu! s:NETRanger.path_under_cursor() abort
  return netranger#api#cur_node_path()
endfu

fu! s:NETRanger.paths_in_range(begin, end) abort
  let paths = []

  let view = winsaveview()
  try
    for line in range(a:begin, a:end)
      call cursor(line, 0)
      call esearch#util#doautocmd('CursorMoved')
      let paths += [self.path_under_cursor()]
    endfor
  finally
    call winrestview(view)
    call esearch#util#doautocmd('CursorMoved')
  endtry

  return paths
endfu
