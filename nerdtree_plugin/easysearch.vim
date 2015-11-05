if get(get(g:, 'esearch_settings', {}), 'nerdtree_plugin', 1)
  for map in keys(esearch#mappings().with_val('"<Plug>(esearch)"'))
    call NERDTreeAddKeyMap({
          \ 'key': map,
          \ 'override': 1,
          \ 'callback': 'NERDTreeEsearchDir',
          \ 'quickhelpText': 'Search in dir',
          \ 'scope': 'Node' })
  endfor

  fu! NERDTreeEsearchDir(node)
    let path = a:node.path
    if path.isDirectory && path.str() !=# getcwd()
      call esearch#pre(0, path.str())
    else
      call esearch#pre(0)
    endif
  endfu
end
