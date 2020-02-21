let s:Vital    = vital#esearch#new()
let s:Dict     = s:Vital.import('Data.Dict')

fu! esearch#undotree#new(state) abort
  let initial = s:node(a:state)
  let node_by_changenr = {}
  let node_by_changenr[0] = initial
  let node_by_changenr[changenr()] = initial
  return {
        \ 'commit':           function('<SID>commit'),
        \ 'checkout':         function('<SID>checkout'),
        \ 'head':             initial,
        \ 'node_by_changenr': node_by_changenr,
        \ }
endfu

fu! s:node(state) abort
  return {
        \ 'changenr': changenr(),
        \ 'state':    a:state,
        \ 'children': [],
        \ }
endfu

fu! s:commit(...) abort dict
  if a:0 == 1
    let state = a:1
  else
    let state = self.head.state
  endif

  let node = s:node(state)
  let self.node_by_changenr[node.changenr] = node
  call add(self.head.children, node)
  let self.head = node
endfu

fu! s:checkout(changenr) abort dict
  let self.head = self.node_by_changenr[a:changenr]
endfu

if g:esearch#env isnot 0
  command! T call s:debug()
  fu! s:debug() abort
    let tree = deepcopy(b:esearch.undotree)

    for node in values(tree.node_by_changenr)
      if has_key(node, 'state')
        unlet node.state
      endif
    endfor

    unlet tree.node_by_changenr
    let tree.active = tree.head.changenr

    for key in keys(tree)
      if type(tree[key]) == type(function('tr'))
        unlet tree[key]
      endif
    endfor

    PP tree
  endfu
endif
