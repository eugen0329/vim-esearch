let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#dirvish#import() abort
  return s:Dirvish
endfu

let s:Dirvish = esearch#compat#filemanager#base#import()

fu! s:Dirvish.path_under_cursor() abort
  return getline('.')
endfu

fu! s:Dirvish.paths_in_range(begin, end) abort
  return getline(a:begin, a:end)
endfu
