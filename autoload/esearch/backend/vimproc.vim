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

let s:requests = {}
let s:last_request_id = 0

fu! esearch#backend#vimproc#init(cmd, pty) abort
  let pipe = vimproc#popen3(
        \ vimproc#util#iconv(a:cmd, &encoding, 'char'), a:pty)
  call pipe.stdin.close()

  let request = {
        \ 'format': '%f:%l:%c:%m,%f:%l:%m',
        \ 'backend': 'vimproc',
        \ 'command': a:cmd,
        \ 'pipe': pipe,
        \ 'data': [],
        \ 'errors': [],
        \ 'async': 1,
        \ '_last_update_time':   esearch#util#timenow(),
        \ 'events': {
        \   'finish':            'ESearchVimProcFinish'.s:last_request_id,
        \   'update':            'ESearchVimProcUpdate'.s:last_request_id,
        \   'trigger_key_press': 'ESearchVimProcTriggerKeypress'.s:last_request_id
        \ }
        \}

  exe 'aug ESearchVimproc'.s:last_request_id
    au!
    exe 'au CursorMoved * call s:_on_cursor_moved('.s:last_request_id.')'
    exe 'au CursorHold  * call s:_on_cursor_hold('.s:last_request_id.')'
  aug END

  let s:requests[s:last_request_id] = request
  let s:last_request_id += 1

  return request
endfu

fu! s:read_data(request) abort
  let request = a:request
  let data = request.pipe.stdout.read_lines(-1, g:esearch#backend#vimproc#read_timeout)
  let request.data += data
endfu

fu! esearch#backend#vimproc#escape_cmd(cmd)
  return esearch#util#shellescape(a:cmd)
endfu

fu! s:read_errors(request)
  let stderr = a:request.pipe.stderr
  if !stderr.eof
    let errors = filter(
          \ stderr.read_lines(-1, g:esearch#backend#vimproc#read_errors_timeout),
          \ "v:val !~ '^\\s*$'")
    let a:request.errors += errors
  endif
endfu

fu! s:_on_cursor_moved(request_id) abort
  let request = s:requests[a:request_id]

  if esearch#util#timenow() < &updatetime/1000.0 + request._last_update_time
    return -1
  endif

  call s:read_data(request)
  exe 'do User '.request.events.update
  let request._last_update_time = esearch#util#timenow()

  if s:completed(request)
    call s:finish(request, a:request_id)
  endif
endfu

fu! s:finish(request, request_id)
  call s:read_errors(a:request)
  " let &updatetime = float2nr(b:updatetime_backup)
  exe 'do User '.a:request.events.finish
  exe 'au! ESearchVimproc'.a:request_id
endfu

fu! s:_on_cursor_hold(request_id)
  let request = s:requests[a:request_id]
  call s:read_data(request)

  let events = request.events
  exe 'do User '.events.update
  let request._last_update_time = esearch#util#timenow()

  if s:completed(request)
    call s:finish(request, a:request_id)
  else
    exe 'do User '.events.trigger_key_press
  endif
endfu

fu! s:completed(request) abort
  if !has_key(g:, 'test')
    let g:test = []
  endif

  return a:request.pipe.stdout.eof &&
        \ (!has_key(a:request, 'out_finish') || a:request.out_finish())
endfu

fu! esearch#backend#vimproc#abort(request) abort
  return a:request.pipe.kill(g:vimproc#SIGTERM)
endfu

fu! esearch#backend#vimproc#init_events() abort
  let b:updatetime_backup = &updatetime
  au BufLeave    <buffer> let  &updatetime = getbufvar(str2nr(expand('<abuf>')), 'updatetime_backup')

  let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)
  au BufEnter    <buffer> call setbufvar(str2nr(expand('<abuf>')), 'updatetime_backup', &updatetime) |
        \ let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)

  au BufUnload <buffer>
        \ call esearch#backend#vimproc#abort(getbufvar(str2nr(expand('<abuf>')), 'esearch').request)
endfu


function! esearch#backend#vimproc#sid()
  return maparg('<SID>', 'n')
endfunction
function! esearch#backend#vimproc#scope()
  return s:
endfunction
nnoremap <SID>  <SID>
