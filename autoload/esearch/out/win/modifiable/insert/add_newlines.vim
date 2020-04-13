fu! esearch#out#win#modifiable#insert#add_newlines#handle(event) abort
  " using recorded original text is the only way to safely recover line1
  " contents as splitting line1 and line2 by col1 and col2 and joining them back
  " is unreliable when pasting huge amount of newlines or when using 3d party plugins
  call setline(a:event.line1, a:event.original_text)
  call deletebufline(bufnr('%'), a:event.line1 + 1, a:event.line2)
  call cursor(a:event.line1, a:event.col1)
  call esearch#changes#undo_state()
  if mode() ==# 'i'
    doau CursorMovedI
  else
    doau CursorMoved
  endif
endfu


