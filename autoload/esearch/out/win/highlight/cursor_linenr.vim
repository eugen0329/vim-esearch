fu! esearch#out#win#highlight#cursor_linenr#init(esearch) abort
  if has('nvim')
    let a:esearch.linenr_ns_id = luaeval('esearch.highlight.CURSOR_LINENR_NS')
  else
    let a:esearch.linenr_hl_id = 0
  endif

  aug esearch_win_hl_cursor_linenr
    au CursorMoved,CursorMovedI <buffer> call s:highlight_cursor_line_number()
  aug END
endfu

fu! esearch#out#win#highlight#cursor_linenr#uninit(esearch) abort
  aug esearch_win_hl_cursor_linenr
    au! * <buffer>
  aug END
  if has('nvim')
    if has_key(a:esearch, 'linenr_ns_id')
      call nvim_buf_clear_namespace(0, a:esearch.linenr_ns_id, 0, -1)
    endif
  elseif has_key(a:esearch, 'linenr_hl_id')
    call esearch#util#safe_matchdelete(a:esearch.linenr_hl_id)
  endif
endfu

fu! esearch#out#win#highlight#cursor_linenr#soft_stop(esearch) abort
  call esearch#out#win#highlight#cursor_linenr#uninit(a:esearch)
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
