fu! esearch#compat#filemanager#nerdtree#import() abort
  return s:NERDTree
endfu

let s:NERDTree = esearch#compat#filemanager#base#import()

fu! s:NERDTree.nearest_dir_or_selected_nodes() abort
  let path = g:NERDTreeFileNode.GetSelected().path
  if !path.isDirectory
    let path =  path.getParent()
  endif

  return [path.str({'escape': 0})]
endfu

fu! s:NERDTree.path_under_cursor() abort
  return g:NERDTreeFileNode.GetSelected().path.str({'escape': 0})
endfu
