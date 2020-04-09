fu! esearch#out#win#highlight#cursor_linenr#init(esearch) abort
  aug esearch_win_highlights
    au CursorMoved,CursorMovedI <buffer> call s:highlight_cursor_line_number()
  aug END
endfu

if has('nvim')
  fu! s:highlight_cursor_line_number() abort
    call luaeval('esearch.highlight.cursor_linenr()')
  endfu
else
  fu! s:highlight_cursor_line_number() abort
    if has_key(b:, 'esearch_linenr_id')
      call esearch#util#safe_matchdelete(b:esearch_linenr_id)
    endif
    let b:esearch_linenr_id = matchadd('esearchCursorLineNr',
          \ '^\s\+\d\+\s\%' . line('.') . 'l', -1)
  endfu
endif
