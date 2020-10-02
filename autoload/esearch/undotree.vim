let s:Log = esearch#log#import()

fu! esearch#undotree#new(state) abort
  let initial = s:node(a:state)
  let nodes = {}
  let nodes[0] = initial
  let nodes[changenr()] = initial
  let head = s:node(copy(a:state))
  let written = extend(copy(head), {'changenr': empty(undotree().entries) ? 0 : changenr()})
  return {
        \ 'commit':   function('<SID>commit'),
        \ 'checkout': function('<SID>checkout'),
        \ 'squash':   function('<SID>squash'),
        \ 'on_write': function('<SID>on_write'),
        \ 'has':      function('<SID>has'),
        \ 'written':  written,
        \ 'head':     initial,
        \ 'nodes':    nodes,
        \}
endfu

fu! s:has(changenr) abort dict
  return has_key(self.nodes, a:changenr)
endfu

fu! s:node(state) abort
  return {'changenr': changenr(), 'state': a:state}
endfu

fu! s:commit(state) abort dict
  let self.head = s:node(a:state)
  let self.nodes[self.head.changenr] = self.head
  return self.head.state
endfu

fu! s:on_write() abort dict
  let self.written = self.head
endfu

fu! s:checkout(changenr, ...) abort dict
  let self.head = self.nodes[a:changenr]
  return self.head.state
endfu

fu! s:squash(state) abort dict
  let self.head = s:node(a:state)
  let self.nodes = {'0': self.head}
  let self.nodes[changenr()] = self.head
endfu
