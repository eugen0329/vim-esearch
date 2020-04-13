fu! esearch#out#win#modifiable#undo#handle(event) abort
  call b:esearch.undotree.checkout(a:event.changenr, a:event.kind)
  call esearch#changes#rewrite_last_state({
        \ 'changenr': changenr(),
        \ })
endfu

