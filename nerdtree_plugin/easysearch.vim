for map in keys(easysearch#mappings().with_val('"<Plug>(easysearch)"'))
  call NERDTreeAddKeyMap({
        \ 'key': map,
        \ 'override': 1,
        \ 'callback': 'NERDTreeEsearchDir',
        \ 'quickhelpText': 'Search in dir',
        \ 'scope': 'Node' })
endfor

fu! NERDTreeEsearchDir(node)
  let path = a:node.path
  if path.isDirectory && !a:node.isRoot()
    call easysearch#pre(0, path.str())
  else
    call easysearch#pre(0)
  endif
endfu
