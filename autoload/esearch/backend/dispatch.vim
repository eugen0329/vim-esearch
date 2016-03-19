fu! esearch#backend#dispatch#init(cmd) abort
  silent exe 'Dispatch! '.a:cmd
  let request = dispatch#request()
  let request.format = '%f:%l:%c:%m,%f:%l:%m'
  let request.background = 1
  let request.backend = 'dispatch'
  return request
endfu

fu! esearch#backend#dispatch#init_events(group) abort
  exe 'augroup ' . a:group
    au CursorMoved <buffer> call s:_on_cursor_moved()
    au CursorHold  <buffer> call s:_on_cursor_hold()
  augroup END
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

" TODO
fu! s:completed(data)
  let parsed_count = b:esearch._lines_iterator + len(b:esearch.__broken_results)
  return !b:esearch.handler_running && b:esearch._lines_iterator == len(b:esearch.parsed)  && len(a:data) ==# parsed_count
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
