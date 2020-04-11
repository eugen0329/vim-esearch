fu! esearch#out#win#highlight#cursor_linenr#init(esearch) abort
  let a:esearch.linenr_hl_id = 0
  aug esearch_win_highlights
    au CursorMoved,CursorMovedI <buffer> call s:highlight_cursor_line_number()
  aug END
endfu

fu! esearch#out#win#highlight#cursor_linenr#uninit(esearch) abort
  call esearch#util#safe_matchdelete(a:esearch.linenr_hl_id)
endfu

if has('nvim')
  fu! s:highlight_cursor_line_number() abort
    call luaeval('esearch.highlight.cursor_linenr()')
  endfu
else
  fu! s:highlight_cursor_line_number() abort
    call esearch#util#safe_matchdelete(b:esearch.linenr_hl_id)
    let b:esearch.linenr_hl_id = matchadd('esearchCursorLineNr',
          \ '^\s\+\d\+\s\%' . line('.') . 'l', -1)
  endfu
endif
