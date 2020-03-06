" taken from eskk.vim and arpeggio.vim
function! esearch#mappings#key2char(key) abort
  if stridx(a:key, '<') ==# -1    " optimization
    return a:key
  endif
  return join(
        \   map(
        \       s:split_to_keys(a:key),
        \       'v:val =~# "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val'
        \   ),
        \   ''
        \)
endfunction

function! s:split_to_keys(lhs) abort "{{{2
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:lhs doesn't directly contain any escape sequences.
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfunction
