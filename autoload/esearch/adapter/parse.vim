if !exists('g:esearch_out_win_parse_using_getqflist')
  let g:esearch_out_win_parse_using_getqflist = g:esearch#has#getqflist_lines
endif
if !exists('g:esearch_out_win_render_using_lua')
  let g:esearch_out_win_render_using_lua = g:esearch#has#lua
endif

fu! esearch#adapter#parse#funcref() abort
  if g:esearch_out_win_render_using_lua
    " TODO move lua chunks to separate files to improve reusability
    let g:esearch#adapter#parse#lua#loaded = g:esearch#adapter#parse#lua#loaded
    return function('esearch#adapter#parse#lua#parse')
  elseif g:esearch_out_win_parse_using_getqflist
    return function('esearch#adapter#parse#viml#getqflines')
  else
    return function('esearch#adapter#parse#viml#legacy')
  endif
endfu
