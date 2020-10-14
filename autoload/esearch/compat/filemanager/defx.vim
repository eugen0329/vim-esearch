let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#defx#import() abort
  return s:Defx
endfu

let s:Defx = esearch#compat#filemanager#base#import()

fu! s:Defx.path_under_cursor() abort
  return defx#get_candidate().action__path
endfu
