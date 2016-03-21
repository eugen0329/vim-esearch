fu! esearch#backend#dispatch#init(cmd) abort
  exe dispatch#compile_command(1, a:cmd, -1)
  let request = dispatch#request()
  let request.format = '%f:%l:%c:%m,%f:%l:%m'
  let request.background = 1
  let request.backend = 'dispatch'
  return request
endfu

fu! esearch#backend#dispatch#init_events() abort
  au CursorMoved <buffer> call s:_on_cursor_moved()
  au CursorHold  <buffer> call s:_on_cursor_hold()
endfu

fu! s:read_data() abort
  let request = b:esearch.request
  if !filereadable(fnameescape(request.file))
    throw "Can't open file for reading" . request.file
  endif
  let file_content = []

  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  let dir = getcwd()
  try
    exe cd fnameescape(request.directory)
    let file_content = filter(readfile(fnameescape(request.file)), '!empty(v:val)')
  catch
    echohl Error | echo v:exception | echohl None
    return file_content
  finally
    exe cd fnameescape(dir)
  endtry

  return file_content
endfu

fu! esearch#backend#dispatch#escape_cmd(cmd)
  return esearch#util#shellescape(a:cmd)
endfu

function! s:running(handler, pid) abort
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
endfunction

" TODO
fu! s:completed(data)
  let nparsed = b:esearch._lines_iterator

  if len(a:data) == nparsed + 1 && esearch#adapter#{b:esearch.adapter}#is_broken_result(a:data[nparsed])
    let nbroken = 1
  else
    let nbroken = 0
  endif

  let handler_running = s:running(b:esearch.request.handler, b:esearch.request.pid)

  return !handler_running && b:esearch._lines_iterator == len(b:esearch.parsed)  && len(a:data) ==# nparsed + nbroken
endfu

fu! s:_on_cursor_moved() abort
  if esearch#util#timenow() < &updatetime/1000.0 + b:esearch._last_update_time
    return -1
  endif
  let data = s:read_data()
  call esearch#out#{b:esearch.out}#update(data)
  if s:completed(data) | call esearch#out#{b:esearch.out}#on_finish() | endif
endfu

fu! s:_on_cursor_hold()
  let data = s:read_data()
  call esearch#out#{b:esearch.out}#update(data)

  if s:completed(data)
    call esearch#out#{b:esearch.out}#on_finish()
  else
    call feedkeys('\<Plug>(easysearch-Nop)')
  endif
endfu


function! esearch#backend#dispatch#sid()
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
