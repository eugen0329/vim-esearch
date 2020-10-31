let s:Log = esearch#log#import()

fu! esearch#undotree#import() abort
  return copy(s:Undotree)
endfu

let s:Undotree = {}

fu! s:Undotree.new(state) abort dict
  let initial = s:node(a:state)
  let nodes = {'0': initial}
  let nodes[changenr()] = initial
  let head = s:node(copy(a:state))
  let written = extend(copy(head), {'changenr': empty(undotree().entries) ? 0 : changenr()})
  return extend(copy(self), {
        \ 'written': written,
        \ 'head':    initial,
        \ 'nodes':   nodes,
        \})
endfu

fu! s:node(state) abort
  return {'changenr': changenr(), 'state': a:state}
endfu

fu! s:Undotree.has(changenr) abort dict
  return has_key(self.nodes, a:changenr)
endfu

fu! s:Undotree.commit(state) abort dict
  let self.head = s:node(a:state)
  let self.nodes[self.head.changenr] = self.head
  return self.head.state
endfu

fu! s:Undotree.on_write() abort dict
  let self.written = self.head
endfu

fu! s:Undotree.checkout(changenr, ...) abort dict
  let self.head = self.nodes[a:changenr]
  return self.head.state
endfu

fu! s:Undotree.squash(state) abort dict
  let self.head = s:node(a:state)
  let self.nodes = {'0': self.head}
  let self.nodes[changenr()] = self.head
endfu
