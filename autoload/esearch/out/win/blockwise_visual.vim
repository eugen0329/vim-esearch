let s:null = 0
let s:separator = ''
let s:linenr_format = ' %3d '

fu! esearch#out#win#blockwise_visual#handle(event) abort
  let state = b:esearch.undotree.head.state
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, state)
  let ctx = contexts.by_line(a:event.line1)
  let line1 = a:event.line1
  let line2 = a:event.line2

  let view = winsaveview()
  call esearch#util#safe_undojoin()

  if ctx.id == 0
    call setline(1, b:esearch.header_text())
    let ctx = ctx.end + 1 <= a:event.line2 ? contexts.by_line(ctx.end + 1) : s:null
    let line1 = 3
  endif

  if ctx isnot# s:null
    for line in range(line1, line2)
      if ctx.begin ==# line
        call setline(ctx.begin, ctx.filename)
      elseif ctx.end ==# line && ctx.id !=# b:esearch.contexts[state.context_ids_map[-1]].id
        let ctx = contexts.by_line(line + 1)
        call setline(line, s:separator)
      else
        let line_in_file = state.line_numbers_map[line]
        let linenr = printf(s:linenr_format, line_in_file)
        if strlen(linenr) + 1 <= a:event.col1
          continue
        endif

        let text = getline(line)
        if a:event.col2 < strlen(linenr) + 1 " deletion happened within linenr, the text is untouched
          " recover linenr and remove leading previous linenr leftover
          let recovered = linenr . text[strlen(linenr) - (a:event.col2 - a:event.col1 + 1) :]
        else " deletion starts within linenr, ends within the text
          " recover linenr and remove leading previous linenr leftover
          let recovered = linenr . text[ a:event.col1 - 1 :]
        endif

        call setline(line, recovered)
      endif
    endfor
  endif

  call winrestview(view)
endfu
