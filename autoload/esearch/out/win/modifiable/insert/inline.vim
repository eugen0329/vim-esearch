fu! esearch#out#win#modifiable#insert#inline#handle(event) abort
  let [line1, col1, col2] = [a:event.line1, a:event.col1, a:event.col2]
  let state   = deepcopy(b:esearch.undotree.head.state)
  let context = esearch#out#win#repo#ctx#new(b:esearch, state).by_line(line1)
  let text    = getline(line1)
  let linenr  = printf(' %3d ', state.line_numbers_map[line1])
  let cursorpos = []

  if line1 == 1
    call setline(line1, b:esearch.header_text())
  elseif line1 == 2 || line1 == context.end && context.end != line('$')
    let text = ''
    call setline(line1, text)
  elseif line1 == context.begin
    let text = context.filename
    call setline(line1, text)
  elseif line1 > 2 && col1 < strlen(linenr) + 1
    " VIRTUAL UI WITH LINE NUMBERS IS AFFECTED:

    if a:event.id ==# 'i-inline-add'
      " Recovered text:
      "   - take   linenr
      "   - concat with extracted chars inserted within a virtual ui
      "   - concat with the rest of the text with removed leftovers from
      "   virtual ui and inserted chars
      let text = linenr
            \ . text[col1 - 1 : col2 - 1]
            \ . text[strlen(linenr) + (col2 - col1 + 1) :]
      let cursorpos = [line1, strlen(linenr) + strlen(text[col1 - 1 : col2 - 1]) + 1]
    elseif a:event.id =~# 'i-inline-delete'
      " Recovered text:
      "   - take   linenr
      "   - concat with original text except linenr and deleted part on the beginning
      let text = linenr . a:event.original_text[ max([col2, strlen(linenr)]) : ]
      let cursorpos = [line1, strlen(linenr) + 1]
    else
      throw 'Unexpected' . string(a:event)
    endif

    call setline(line1, text)
  endif

  if !empty(cursorpos)
    call esearch#changes#rewrite_last_state({
          \ 'line': cursorpos[0],
          \ 'col':  cursorpos[1],
          \ })
    call cursor(cursorpos)
    if mode() ==# 'i'
      doau CursorMovedI
    else
      doau CursorMoved
    endif
  endif
  call esearch#changes#rewrite_last_state({ 'current_line': text })
  call b:esearch.undotree.synchronize()
endfu

