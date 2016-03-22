let to_be_empty = {}
function! to_be_empty.match(actual)
  return empty(a:actual)
endfunction
call vspec#customize_matcher('to_be_empty', to_be_empty)
