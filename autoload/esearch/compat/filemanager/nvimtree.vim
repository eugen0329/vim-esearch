fu! esearch#compat#filemanager#nvimtree#import() abort
  return s:NVIMTree
endfu

let s:NVIMTree = esearch#compat#filemanager#base#import()

fu! s:NVIMTree.path_under_cursor() abort
  return luaeval("require'esearch.nvim.filemanager.nvimtree'.path_under_cursor()")
endfu

fu! s:NVIMTree.nearest_dir_or_selected_nodes() abort
  let nodes = luaeval("require'esearch.nvim.filemanager.nvimtree'.selected_nodes()")

  if len(nodes) == 0
    return [s:NVIMTree.path_under_cursor()]
  else
    return nodes
  endif
endfu
