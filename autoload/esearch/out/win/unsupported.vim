fu! esearch#out#win#unsupported#handle(event) abort
  call b:esearch.undotree.mark_block_as_corrupted()
  silent undo

  " TODO cannot undo a:event.id =~# 'i-add-newline'
  call b:esearch.undotree.checkout(changenr())
  call esearch#changes#undo_state()
endfu

