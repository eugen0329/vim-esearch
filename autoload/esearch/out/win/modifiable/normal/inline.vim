fu! esearch#out#win#modifiable#normal#inline#handle(event) abort
  " TODO will be refactored
  let [line1, col1, col2] = [a:event.line1, a:event.col1, a:event.col2]
  let state = b:esearch.undotree.head.state
  let context = esearch#out#win#repo#ctx#new(b:esearch, state).by_line(line1)

  let text = getline(line1)
  let linenr = printf(' %3d ', state.line_numbers_map[line1])

  if line1 == 1
    call setline(line1, b:esearch.header_text())
  elseif line1 == context.begin
    " it's a filename, restoring
    call setline(line1, fnameescape(context.filename))
  elseif line1 > 2 && col1 < strlen(linenr) + 1
    " VIRTUAL UI WITH LINE NUMBERS IS AFFECTED:

    if col2 < strlen(linenr) + 1 " deletion happened within linenr, the text is untouched
      " recover linenr and remove leading previous linenr leftover
      let text = linenr . text[strlen(linenr) - (col2 - col1 + 1) :]
    else " deletion starts within linenr, ends within the text
      " recover linenr and remove leading previous linenr leftover
      let text = linenr . text[ col1 - 1 :]
    endif
    " let text = linenr . text[ [col1, col2, strlen(linenr)] :]
    call setline(line1, text)
  endif

  call b:esearch.undotree.synchronize()
endfu
