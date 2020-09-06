let s:separator = ''

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#modifiable#blockwise_visual#handle(event) abort
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
        call setline(ctx.begin, fnameescape(ctx.filename))
      elseif ctx.end ==# line && ctx.id !=# state.ctx_ids_map[-1]
        let ctx = contexts.by_line(line + 1)
        call setline(line, s:separator)
      else
        let line_in_file = state.line_numbers_map[line]
        let linenr = printf(g:esearch#out#win#linenr_fmt, line_in_file)
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
