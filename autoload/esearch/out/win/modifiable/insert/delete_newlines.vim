fu! esearch#out#win#modifiable#insert#delete_newlines#handle(event) abort
  let [line1, line2, col1, col2] = [a:event.line1, a:event.line2, a:event.col1, a:event.col2]

  if a:event.id ==# 'i-delete-newline-right'
    let text = getline(line1)

    if col1 < 2 " current line was blank
      call setline(line1, '')
      call append(line1, text)
    else
      call setline(line1, text[0: max([0, col1 - 2])])
      call append(line1, text[ col1 - 1 :])
    endif

    call esearch#changes#rewrite_last_state({
          \ 'current_line': text[ : max([0, col1 - 2]) ],
          \ 'line':         line1,
          \ 'size':         line('$'),
          \ })
  else
    let text = getline(line1)
    if col1 < 2 " previous line was blank
      call setline(line1, '')
    else
      call setline(line1, text[0: col1 - 2])
    endif
    call append(line1, text[ col1 - 1 :])
    call cursor(line2, 1)
    call esearch#changes#rewrite_last_state({
          \ 'current_line': text[ col1 - 1 :],
          \ 'line':         line2,
          \ 'size':         line('$'),
          \ 'col':          1,
          \ })
    if mode() ==# 'i'
      doau CursorMovedI
    else
      doau CursorMoved
    endif
  endif
  call b:esearch.undotree.synchronize()
endfu

