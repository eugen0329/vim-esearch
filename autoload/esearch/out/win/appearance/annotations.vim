fu! esearch#out#win#appearance#annotations#init(esearch) abort
  if a:esearch.win_context_len_annotations
    call luaeval('esearch.appearance.buf_attach_annotations()')
  endif
endfu

fu! esearch#out#win#appearance#annotations#uninit(esearch) abort
  if a:esearch.win_context_len_annotations
    call luaeval('esearch.appearance.buf_clear_annotations()')
  endif
endfu
