if !exists('g:esearch_out_win_render_using_lua')
  let g:esearch_out_win_render_using_lua = g:esearch#has#lua
endif

fu! esearch#adapter#parse#funcref() abort
  if g:esearch_out_win_render_using_lua
    " TODO move lua chunks to separate files to improve reusability
    return esearch#adapter#parse#lua#funcref()
  else
    return esearch#adapter#parse#viml#legacy_funcref()
  endif
endfu
