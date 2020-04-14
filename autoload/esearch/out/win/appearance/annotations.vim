fu! esearch#out#win#appearance#annotations#init(esearch) abort
  if g:esearch_win_results_len_annotations
    call luaeval('esearch.appearance.buf_attach_annotations()')
  endif
endfu

fu! esearch#out#win#appearance#annotations#uninit(esearch) abort
  if g:esearch_win_results_len_annotations
    call luaeval('esearch.appearance.buf_clear_annotations()')
  endif
endfu
