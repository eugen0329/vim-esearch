fu! esearch#compat#filemanager#nerdtree#import() abort
  return s:NERDTree
endfu

let s:NERDTree = esearch#compat#filemanager#base#import()

fu! s:NERDTree.nearest_dir_or_selected_nodes() abort
  let path = s:get_selected_node().path
  if !path.isDirectory
    let path =  path.getParent()
  endif

  return [path.str({'escape': 0})]
endfu

fu! s:NERDTree.path_under_cursor() abort
  return s:get_selected_node().path.str({'escape': 0})
endfu

fu! s:get_selected_node() abort
  let selected = g:NERDTreeFileNode.GetSelected()
  return empty(selected) ? g:NERDTreeFileNode.GetRootForTab() : selected
endfu
