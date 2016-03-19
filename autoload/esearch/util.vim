fu! esearch#util#parse_results(file, from, to, broken_results) abort
  if empty(a:file) | return [] | endif
  let r = '^\(.\{-}\)\:\(\d\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'
  let results = []

  for i in range(a:from, a:to)
    let el = matchlist(a:file[i], r)[1:4]
    if empty(el)
      if index(a:broken_results, a:file[i]) < 0
        call add(a:broken_results, a:file[i])
      endif
      continue
    endif
    let new_elem = { 'fname': el[0], 'lnum': el[1], 'col': el[2], 'text': el[3] }
    call add(results, new_elem)
  endfor
  return results
endfu

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

fu! esearch#util#shellescape(str) abort
  return shellescape(a:str, g:esearch.escape_special)
endfu

fu! esearch#util#timenow() abort
  let now = reltime()
  return str2float(reltimestr([now[0] % 10000, now[1]/1000 * 1000]))
endfu

fu! esearch#util#visual_selection() abort
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfu


" Extracted from tpope/dispatch
fu! esearch#util#request_status() abort
  let request = b:request
  try
    let status = str2nr(readfile(request.file . '.complete', 1)[0])
  catch
    let status = -1
  endtry
  return status
endfu

fu! esearch#util#cgetfile(request) abort
  let request = a:request
  if !filereadable(fnameescape(request.file))
    throw "Can't open file for reading" . request.file
  endif
  let file_content = []

  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  let dir = getcwd()
  try
    exe cd fnameescape(request.directory)
    let file_content = filter(readfile(fnameescape(request.file)), '!empty(v:val)')
  finally
    exe cd fnameescape(dir)
  endtry

  return file_content
endfu

fu! esearch#util#running(handler, pid) abort
  if empty(a:pid)
    return 0
  elseif exists('*dispatch#'.a:handler.'#running')
    return dispatch#{a:handler}#running(a:pid)
  elseif has('win32')
    let tasklist_cmd = 'tasklist /fi "pid eq '.a:pid.'"'
    if &shellxquote ==# '"'
      let tasklist_cmd = substitute(tasklist_cmd, '"', "'", "g")
    endif
    return system(tasklist_cmd) =~# '==='
  else
    call system('kill -0 '.a:pid)
    return !v:shell_error
  endif
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
