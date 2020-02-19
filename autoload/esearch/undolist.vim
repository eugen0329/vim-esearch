let s:Vital    = vital#esearch#new()
let s:Dict     = s:Vital.import('Data.Dict')

" it doesn't map undotree directly and probably won't, so git glossary is used
" here (probably will be changed in future)
fu! esearch#undolist#new(state) abort
  let initial_entry = {
        \ 'changenr': changenr(),
        \ 'state':    deepcopy(a:state)
        \ }
  let stack = [initial_entry] " tree structure will be implemented later

  return {
        \ 'stack':     stack,
        \ 'head':      function('<SID>head'),
        \ 'commit':    function('<SID>commit'),
        \ 'revert':    function('<SID>revert'),
        \}
endfu

fu! s:head() abort dict
  return self.stack[-1]
endfu

fu! s:commit(...) abort dict
  if a:0 == 1
    let state = a:1
  else
    let state = self.head().state
  endif

  call add(self.stack, {
        \ 'changenr': changenr(),
        \ 'state':    state
        \})
endfu

fu! s:revert() abort dict
  call remove(self.stack, -1)
endfu
