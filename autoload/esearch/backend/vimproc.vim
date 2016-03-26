if !exists('g:esearch#backend#vimproc#updatetime')
  let g:esearch#backend#vimproc#updatetime = 300.0
endif

if !exists('g:esearch#backend#vimproc#read_timeout')
  let g:esearch#backend#vimproc#read_timeout = 100.0
endif

" Errors are handled after
if !exists('g:esearch#backend#vimproc#read_errors_timeout')
  let g:esearch#backend#vimproc#read_errors_timeout =
        \ g:esearch#backend#vimproc#read_timeout * 5
endif

fu! esearch#backend#vimproc#init(cmd, pty) abort
  let pipe = vimproc#popen3(
        \ vimproc#util#iconv(a:cmd, &encoding, 'char'), a:pty)
  call pipe.stdin.close()

  let request = {
        \ 'format': '%f:%l:%c:%m,%f:%l:%m',
        \ 'backend': 'vimproc',
        \ 'pipe': pipe,
        \ 'data': [],
        \ 'errors': [],
        \}

  return request
endfu

fu! s:read_data() abort
  let request = b:esearch.request
  let data = request.pipe.stdout.read_lines(-1, g:esearch#backend#vimproc#read_timeout)
  let request.data += data
endfu

fu! esearch#backend#vimproc#escape_cmd(cmd)
  return esearch#util#shellescape(a:cmd)
endfu

fu! s:read_errors()
  let stderr = b:esearch.request.pipe.stderr
  if !stderr.eof
    let errors = filter(
          \ stderr.read_lines(-1, g:esearch#backend#vimproc#read_errors_timeout),
          \ "v:val !~ '^\\s*$'")
    let b:esearch.request.errors += errors
  endif
endfu

fu! s:_on_cursor_moved() abort
  if esearch#util#timenow() < &updatetime/1000.0 + b:esearch._last_update_time
    return -1
  endif

  call s:read_data()
  call esearch#out#{b:esearch.out}#update()

  if s:completed(b:esearch.request.data)
    call s:read_errors()
    let &updatetime = float2nr(b:updatetime_backup)
    call esearch#out#{b:esearch.out}#on_finish()
  endif
endfu

fu! s:_on_cursor_hold()
  call s:read_data()
  call esearch#out#{b:esearch.out}#update()

  if s:completed(b:esearch.request.data)
    call s:read_errors()
    let &updatetime = float2nr(b:updatetime_backup)
    call esearch#out#{b:esearch.out}#on_finish()
  else
    call esearch#out#{b:esearch.out}#trigger_key_press()
  endif
endfu


function! esearch#backend#vimproc#sid()
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>


" TODO
fu! s:completed(data)
  return b:esearch.request.pipe.stdout.eof &&
        \ b:esearch.data_ptr == len(b:esearch.request.data)
endfu


fu! esearch#backend#vimproc#init_events() abort
  au CursorMoved <buffer> call s:_on_cursor_moved()
  au CursorHold  <buffer> call s:_on_cursor_hold()

  let b:updatetime_backup = &updatetime
  au BufLeave    <buffer> let  &updatetime = b:updatetime_backup

  let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)
  au BufEnter    <buffer> let  b:updatetime_backup = &updatetime |
        \ let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)
endfu
