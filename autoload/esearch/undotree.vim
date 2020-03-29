let s:Vital    = vital#esearch#new()
let s:Dict     = s:Vital.import('Data.Dict')
let s:Message  = s:Vital.import('Vim.Message')

fu! esearch#undotree#new(state) abort
  let initial = s:node(a:state)
  let nodes = {}
  let nodes[0] = initial
  let nodes[changenr()] = initial
  let head = s:node(deepcopy(a:state))
  return {
        \ 'synchronize':             function('<SID>synchronize'),
        \ 'mark_block_as_corrupted': function('<SID>mark_block_as_corrupted'),
        \ 'checkout':                function('<SID>checkout'),
        \ 'locate_synchronized':     function('<SID>locate_synchronized'),
        \ 'head':                    initial,
        \ 'nodes':                   nodes,
        \ }
endfu

fu! s:node(state) abort
  return {
        \ 'changenr': changenr(),
        \ 'state':    a:state,
        \ }
endfu

" Synchronizes with builtin undotree
fu! s:synchronize(...) abort dict
  if a:0 == 1
    let state = a:1
  else
    let state = self.head.state
  endif

  let node = s:node(state)
  let self.nodes[node.changenr] = node
  let self.head = node
endfu

fu! s:mark_block_as_corrupted(...) abort dict
  " If the block contains state recovered using :undo (instead of setlines()).
  " In future can be used to notify users on a try to checkout to this entry,
  " that it contains invalid buffer state and should not be replayed
  call self.synchronize()
  let self.head.corrupted = 1
endfu

fu! s:checkout(changenr, ...) abort dict
  if has_key(self.nodes, a:changenr)
    let self.head = self.nodes[a:changenr]
    return
  endif

  let command = get(a:000, 0, 'undo')
  let found_changenr = self.locate_synchronized(command)

  if found_changenr >= 0
    let format = 'Not synchronized undo block encountered, jumping to change number {%d}'
    let message = printf(format, found_changenr)
  else
    let found_changenr = self.locate_synchronized('undo')
    if found_changenr < 0
      throw 'TODO handle locate_synchronized fail with disabled editing'
    endif
    let message = printf("Can't jump to change number {%d}, undo to {%d}",
          \ a:changenr, found_changenr)
  endif

  let self.head = self.nodes[found_changenr]
  call s:Message.echo('ErrorMsg', message)
endfu

" traverse undotree using :undo or :redo using command specified in a:command
fu! s:locate_synchronized(command) abort dict
  let found_changenr = -1

  while changenr() != found_changenr
    execute 'silent ' . a:command
    let found_changenr = changenr()

    if has_key(self.nodes, found_changenr)
      return found_changenr
    endif
  endwhile

  return -1
endfu

if g:esearch#env isnot# 0
  command! T call s:debug()
  fu! s:debug() abort
    let tree = deepcopy(b:esearch.undotree)

    let tree.active = tree.head.changenr
    let tree.nodes = map(keys(tree.nodes), 'str2nr(v:val)')
    unlet tree.head

    for key in keys(tree)
      if type(tree[key]) == type(function('tr'))
        unlet tree[key]
      endif
    endfor

    PP tree
  endfu
endif
