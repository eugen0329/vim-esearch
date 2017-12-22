if get(get(g:, 'esearch', {}), 'nerdtree_plugin', 1)
  for map in esearch#_mappings()
    if map.rhs ==# '<Plug>(esearch)'
      call NERDTreeAddKeyMap({
            \ 'key': map.lhs,
            \ 'override': 1,
            \ 'callback': 'NERDTreeEsearchDir',
            \ 'quickhelpText': 'Search in dir',
            \ 'scope': 'Node' })
    endif
  endfor

  fu! NERDTreeEsearchDir(node) abort
    let path = a:node.path
    let cwd = path.isDirectory ? path.str() : path.getParent().str()
    return esearch#init({ 'cwd': cwd })
  endfu
end
