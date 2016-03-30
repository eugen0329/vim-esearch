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

  if !exists('s:request_counter')
    let s:request_counter = 0
  endif

  let s:request_counter += 1

  let request = {
        \ 'format': '%f:%l:%c:%m,%f:%l:%m',
        \ 'backend': 'vimproc',
        \ 'pipe': pipe,
        \ 'data': [],
        \ 'errors': [],
        \ 'events': {
        \   'finish':            'ESearchVimProcFinish'.s:request_counter,
        \   'update':            'ESearchVimProcUpdate'.s:request_counter,
        \   'trigger_key_press': 'ESearchVimProcTriggerKeypress'.s:request_counter
        \ }
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
  exe 'doau User '.b:esearch.request.events.update

  if s:completed(b:esearch.request.data)
    call s:read_errors()
    let &updatetime = float2nr(b:updatetime_backup)
    exe 'doau User '.b:esearch.request.events.finish
  endif
endfu

fu! s:_on_cursor_hold()
  call s:read_data()

  let events = b:esearch.request.events
  exe 'doau User '.events.update

  if s:completed(b:esearch.request.data)
    call s:read_errors()
    let &updatetime = float2nr(b:updatetime_backup)
    exe 'doau User '.events.finish
  else
    exe 'doau User '.events.trigger_key_press
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

fu! s:abort_job(buf)
  call getbufvar(a:buf, 'esearch').request.pipe.kill(g:vimproc#SIGTERM)
endfu

fu! esearch#backend#vimproc#init_events() abort
  au CursorMoved <buffer> call s:_on_cursor_moved()
  au CursorHold  <buffer> call s:_on_cursor_hold()

  let b:updatetime_backup = &updatetime
  au BufLeave    <buffer> let  &updatetime = b:updatetime_backup

  let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)
  au BufEnter    <buffer> let  b:updatetime_backup = &updatetime |
        \ let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)

  au BufUnload <buffer> call s:abort_job(str2nr(expand('<abuf>')))
endfu
