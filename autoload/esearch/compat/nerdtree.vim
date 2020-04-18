fu! esearch#compat#nerdtree#opts(esearch) abort
  let esearch = a:esearch

  if get(esearch, 'visualmode', 0)
    let begin = getpos("'<")[1]
    let end   = getpos("'>")[1]

    let esearch.paths = get(esearch, 'paths', [])
    let view = winsaveview()
    try
      for line in range(begin, end)
        call cursor(line, 0)
        let esearch.paths += [g:NERDTreeFileNode.GetSelected().path.str()]
      endfor
    finally
      call winrestview(view)
    endtry
  else
    let path = g:NERDTreeFileNode.GetSelected().path
    let cwd = path.isDirectory ? path.str() : path.getParent().str()
    let esearch.cwd = cwd
  endif

  return esearch
endfu
