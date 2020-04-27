fu! esearch#compat#filer#nerdtree#import() abort
  return s:NERDTree
endfu

let s:NERDTree = copy(esearch#compat#filer#base#import())

fu! s:NERDTree.nearest_directory_path()
  let path = g:NERDTreeFileNode.GetSelected().path
  if !path.isDirectory
    let path =  path.getParent()
  endif

  return path.str({'escape': 0})
endfu

fu! s:NERDTree.path_under_cursor()
  return g:NERDTreeFileNode.GetSelected().path.str({'escape': 0})
endfu
