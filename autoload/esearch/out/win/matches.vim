fu! esearch#out#win#matches#pattern_each(esearch) abort
  if !has_key(a:esearch.pattern, 'vim') | return | endif
  " To avoid matching pseudo LineNr
  if a:esearch.pattern.vim[0] ==# '^'
    return '\%>3l\%(\s\+\d\+\s\)\@<='.a:esearch.pattern.vim[1:-1]
  endif

  return '\%>3l\%(\s\+\d\+\s.*\)\@<='.a:esearch.pattern.vim
endfu
