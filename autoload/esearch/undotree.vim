let s:Log = esearch#log#import()

fu! esearch#undotree#new(state) abort
  let initial = s:node(a:state)
  let nodes = {}
  let nodes[0] = initial
  let nodes[changenr()] = initial
  let head = s:node(deepcopy(a:state))
  let written = extend(copy(head), {'changenr': empty(undotree().entries) ? 0 : changenr()})
  return {
        \ 'commit':             function('<SID>commit'),
        \ 'mark_block_as_corrupted': function('<SID>mark_block_as_corrupted'),
        \ 'checkout':                function('<SID>checkout'),
        \ 'squash':                  function('<SID>squash'),
        \ 'locate_synchronized':     function('<SID>locate_synchronized'),
        \ 'on_write':                function('<SID>on_write'),
        \ 'written':                 written,
        \ 'head':                    initial,
        \ 'nodes':                   nodes,
        \}
endfu

fu! s:node(state) abort
  return {'changenr': changenr(), 'state': a:state}
endfu

" Synchronizes with builtin undotree
fu! s:commit(...) abort dict
  let state = a:0 ? a:1 : self.head.state
  let self.head = s:node(state)
  let self.nodes[self.head.changenr] = self.head
endfu

fu! s:on_write() abort dict
  let self.written = self.head
endfu

fu! s:mark_block_as_corrupted(...) abort dict
 
 " If the block contains state recovered using :undo (instead of setline()).
  " In future can be used to notify users on a try to checkout to this entry,
  " that it contains invalid buffer state and should not be replayed
  call self.commit()
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
  call s:Log.error(message)
endfu

fu! s:squash(state) abort dict
  let self.head = s:node(a:state)
  let self.nodes = {'0': self.head}
  let self.nodes[changenr()] = self.head
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
