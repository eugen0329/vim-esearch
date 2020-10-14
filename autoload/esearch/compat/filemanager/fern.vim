let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#fern#import() abort
  return s:Fern
endfu

let s:Fern = copy(esearch#compat#filemanager#base#import())

fu! s:Fern.path_under_cursor() abort
  return fern#helper#new().sync.get_cursor_node()._path
endfu
