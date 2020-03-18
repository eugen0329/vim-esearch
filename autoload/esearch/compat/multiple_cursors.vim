fu! esearch#compat#multiple_cursors#init() abort
  if exists('g:esearch_multiple_cursors_loaded')
    return
  endif
  let g:esearch_multiple_cursors_loaded = 1

  au User MultipleCursorsPre let b:__undojoin_executed = 1
  au User MultipleCursorsPost let b:__undojoin_executed = 0
endfu
