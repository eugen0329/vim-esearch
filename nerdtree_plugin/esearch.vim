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
    if path.isDirectory && path.str() !=# getcwd()
      call esearch#init({ 'cwd': path.str() })
    else
      call esearch#init()
    endif
  endfu
end
