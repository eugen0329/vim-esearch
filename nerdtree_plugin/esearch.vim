if get(get(g:, 'esearch', {}), 'nerdtree_plugin', 1)
  for map in keys(esearch#_mappings().with_val('<Plug>(esearch)'))
    call NERDTreeAddKeyMap({
          \ 'key': map,
          \ 'override': 1,
          \ 'callback': 'NERDTreeEsearchDir',
          \ 'quickhelpText': 'Search in dir',
          \ 'scope': 'Node' })
  endfor

  fu! NERDTreeEsearchDir(node) abort
    let path = a:node.path
    let cwd = path.isDirectory ? path.str() : path.getParent().str()
    return esearch#init({ 'cwd': cwd })
  endfu
end
