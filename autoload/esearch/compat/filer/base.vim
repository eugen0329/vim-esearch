fu! esearch#compat#filer#base#import() abort
  return s:Base
endfu

let s:Base = {}

fu! s:Base.paths_in_range(begin, end) abort
  let paths = []

  let view = winsaveview()
  try
    for line in range(a:begin, a:end)
      call cursor(line, 0)
      let path = self.path_under_cursor()
      let paths += [path]
    endfor
  finally
    call winrestview(view)
  endtry

  return paths
endfu
