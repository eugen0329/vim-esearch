let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#fern#import() abort
  return s:Fern
endfu

let s:Fern = esearch#compat#filemanager#base#import()

fu! s:Fern.path_under_cursor() abort
  return fern#helper#new().sync.get_cursor_node()._path
endfu

fu! s:Fern.nearest_dir_or_selected_nodes() abort
  let nodes = fern#helper#new().sync.get_selected_nodes()
  if len(nodes) == 1
    let path = nodes[0]._path
    return isdirectory(path) ? [path] : [s:Filepath.dirname(path)]
  else
    return map(nodes, 'v:val._path')
  endif
endfu
