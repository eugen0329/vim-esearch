fu! esearch#out#win#matches#pattern_each(esearch) abort
  if !has_key(a:esearch.pattern, 'vim') | return '' | endif
  " To avoid matching pseudo LineNr
  if a:esearch.pattern.vim[0] ==# '^'
    return g:esearch#out#win#ignore_ui_hat_re . '\%(' . a:esearch.pattern.vim[1:] . '\M\)'
  endif

  return g:esearch#out#win#ignore_ui_re . '\%(' . a:esearch.pattern.vim . '\M\)'
endfu
