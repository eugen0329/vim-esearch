fu! esearch#util#flatten(list)
  let flatten = []
  for elem in a:list
    if type(elem) == type([])
      call extend(flatten, esearch#util#flatten(elem))
    else
      call add(flatten, elem)
    endif
    unlet elem
  endfor
  return flatten
endfu

function! esearch#util#uniq(list) abort
  let i = 0
  let seen = {}
  while i < len(a:list)
    if (a:list[i] ==# '' && exists('empty')) || has_key(seen,a:list[i])
      call remove(a:list,i)
    elseif a:list[i] ==# ''
      let i += 1
      let empty = 1
    else
      let seen[a:list[i]] = 1
      let i += 1
    endif
  endwhile
  return a:list
endfunction

fu! esearch#util#btrunc(str, center, lw, rw) abort
  " om - omission, lw/rw - with from the left(right)
  let om = '…'

  let l = (a:lw > a:center ? 0 : a:center - a:lw + len(om))
  let r = (len(a:str) <= a:center + a:rw ? len(a:str)-1 : a:center+a:rw-len(om))

  return (l == 0 ? '' : om) . a:str[l : r] . (r == len(a:str)-1 ? '' : om)
endfu

fu! esearch#util#trunc(str, size) abort
  if len(a:str) > a:size
    return a:str[:a:size] . '…'
  endif

  return a:str
endfu

fu! esearch#util#stringify_mapping(map)
  let str = substitute(a:map, '<[Cc]-\([^>]\)>', 'Ctrl-\1 ', 'g')
  let str = substitute(str, '<[Ss]-\([^>]\)>', 'Alt-\1 ', 'g')
  let str = substitute(str, '<[AMam]-\([^>]\)>', 'Alt-\1 ', 'g')
  " TODO check if unicod is allowed
  let str = substitute(str, '<[Dd]-\([^>]\)>', '⌘-\1 ', 'g')
  let str = substitute(str, '\s\+$', '', 'g')
  return str
endfu

fu! esearch#util#shellescape(str) abort
  return shellescape(a:str, g:esearch.escape_special)
endfu

fu! esearch#util#timenow() abort
  let now = reltime()
  return str2float(reltimestr([now[0] % 10000, now[1]/1000 * 1000]))
endfu

fu! esearch#util#has_unicode()
  return &termencoding ==# 'utf-8' || &encoding ==# 'utf-8'
endfu

fu! esearch#util#visual_selection() abort
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfu

fu! esearch#util#set(key, val) dict abort
  let self[a:key] = a:val
  return self
endfu

fu! esearch#util#get(key) dict abort
  return self[a:key]
endfu

fu! esearch#util#dict() dict abort
  return filter(copy(self), 'type(v:val) != '.type(function("tr")))
endfu

fu! esearch#util#with_val(val) dict abort
  return filter(copy(self), 'type(v:val) == type('.a:val.') && v:val==# '.a:val)
endfu

fu! esearch#util#key(val) dict abort
  return get(keys(filter(copy(self), 'type(v:val) == type('.a:val.') && v:val==# '.a:val)), 0, 0)
endfu

fu! esearch#util#withou(key) dict abort
  return filter(copy(self), 'v:key !=# '.a:val)
endfu

fu! esearch#util#without_val(val) dict abort
  return filter(copy(self), 'type(v:val) != type('.a:val.') || v:val!=# '.a:val)
endfu

fu! esearch#util#require(...) dict abort
  return filter(copy(self), 'index(a:000, v:key) >= 0')
endfu

fu! esearch#util#set_default(key, default) dict abort
  if !has_key(self, a:key)
    let self[a:key] = a:default
  endif
  return self
endfu

fu! esearch#util#highlight(highlight, str, ...)
  exe "echohl " . a:highlight . "| echon " . strtrans(string(a:str))
  if a:0 && !a:1
    echohl 'Normal'
  endif
endfu
