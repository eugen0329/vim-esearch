let s:null = 0

fu! esearch#writer#buffer#write(diff, search_buffer) abort
  return s:new(a:diff, a:search_buffer).write()
endfu

fu! s:new(diff, search_buffer) abort
  return {
        \ 'diff':                  a:diff,
        \ 'search_buffer':         a:search_buffer,
        \ 'modified_line':         s:null,
        \ 'write':                 function('<SID>write'),
        \ 'replace_lines':         function('<SID>replace_lines'),
        \ 'delete_lines':          function('<SID>delete_lines'),
        \ 'try_jump_to_diff_line': function('<SID>try_jump_to_diff_line'),
        \ }
endfu

fu! s:write() abort dict
  call setbufvar(self.search_buffer, '&modified', 0)

  for [filename, changes] in items(self.diff.files)
    exe '$tabnew ' . filename

    if !empty(get(changes, 'modified', {}))
      call self.replace_lines(changes.modified)
    endif
    call self.try_jump_to_diff_line()

    if !empty(get(changes, 'deleted', []))
      call self.delete_lines(changes.deleted)
    endif
    call self.try_jump_to_diff_line()

    let self.modified_line = s:null
  endfor
  redraw!
endfu

fu! s:try_jump_to_diff_line() abort dict
  if self.modified_line isnot# s:null && line('.') != self.modified_line
    call cursor(self.modified_line, 1)
  endif
endfu

fu! s:replace_lines(modified) abort dict
  let lines_with_text_to_replace = items(a:modified)

  for [line, text] in lines_with_text_to_replace
    call setline(line, text)
  endfor

  if self.modified_line is# s:null
    let [first_replaced_line, _text] = lines_with_text_to_replace[0]
    let self.modified_line = first_replaced_line
  endif
endfu

fu! s:delete_lines(deleted) abort dict
  let lines_to_delete = reverse(sort(a:deleted, 'n'))

  for line in lines_to_delete
    call deletebufline(bufnr('%'), line)
  endfor

  if self.modified_line is# s:null
    let self.modified_line = max([1, lines_to_delete[0] - 1])
  endif
endfu
