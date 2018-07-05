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
let s:incrementable_internal_id = 0

fu! esearch#backend#vimproc#init(cmd, pty) abort
  let request = {
        \ 'internal_id': s:incrementable_internal_id,
        \ 'format': '%f:%l:%c:%m,%f:%l:%m',
        \ 'backend': 'vimproc',
        \ 'command': a:cmd,
        \ 'data': [],
        \ 'errors': [],
        \ 'async': 1,
        \ 'pty': a:pty,
        \ 'status': 0,
        \ 'finished': 0,
        \ 'aborted': 0,
        \ '_last_update_time':   esearch#util#timenow(),
        \ 'events': {
        \   'finish':            'ESearchVimProcFinish'.s:incrementable_internal_id,
        \   'update':            'ESearchVimProcUpdate'.s:incrementable_internal_id,
        \   'trigger_key_press': 'ESearchVimProcTriggerKeypress'.s:incrementable_internal_id
        \ }
        \}

  let s:requests[s:incrementable_internal_id] = request
  let s:incrementable_internal_id += 1

  return request
endfu

fu! esearch#backend#vimproc#run(request) abort
  let pipe = vimproc#popen3(
        \ vimproc#util#iconv(a:request.command, &encoding, 'char'), a:request.pty)
  call pipe.stdin.close()

  let a:request.pipe = pipe

  exe 'aug ESearchVimproc'.a:request.internal_id
    au!
    exe 'au CursorMoved * call s:_on_cursor_moved('.a:request.internal_id.')'
    exe 'au CursorHold  * call s:_on_cursor_hold('. a:request.internal_id.')'
  aug END
endfu

fu! esearch#backend#vimproc#escape_cmd(cmd) abort
  return esearch#util#shellescape(a:cmd)
endfu

fu! s:read_errors(request) abort
  let stderr = a:request.pipe.stderr
  if !stderr.eof
    let errors = filter(
          \ stderr.read_lines(-1, g:esearch#backend#vimproc#read_errors_timeout),
          \ "v:val !~# '^\\s*$'")
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

fu! s:finish(request, request_id) abort
  call s:read_errors(a:request)
  if has_key(a:request, 'bufnr')
    let ut_bak = float2nr(getbufvar(a:request.bufnr, 'updatetime_backup'))
    call setbufvar(a:request.bufnr, '&ut', ut_bak)
  endif
  let [a:request.cond, a:request.status] = a:request.pipe.waitpid()
  let a:request.finished = 1
  if !a:request.aborted
    exe 'do User '.a:request.events.finish
  endif
  exe 'au! ESearchVimproc'.a:request_id
endfu

fu! s:_on_cursor_hold(request_id) abort
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

fu! s:read_data(request) abort
  let request = a:request
  let data = request.pipe.stdout.read_lines(-1, g:esearch#backend#vimproc#read_timeout)
  let request.data += data
endfu

fu! s:completed(request) abort
  if !has_key(g:, 'test')
    let g:test = []
  endif

  return a:request.pipe.stdout.eof &&
        \ (!has_key(a:request, 'out_finish') || a:request.out_finish())
endfu

fu! esearch#backend#vimproc#abort(bufnr) abort
  " FIXME unify with out#qflist
  let esearch = getbufvar(a:bufnr, 'esearch', get(g:, 'esearch_qf', {}))
  if empty(esearch)
    return -1
  endif

  let esearch.request.aborted = 1
  return esearch.request.pipe.kill(g:vimproc#SIGKILL)
endfu

fu! esearch#backend#vimproc#init_events() abort
  let b:updatetime_backup = &updatetime
  au BufLeave    <buffer> let  &updatetime = getbufvar(str2nr(expand('<abuf>')), 'updatetime_backup')

  let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)
  au BufEnter    <buffer> call setbufvar(str2nr(expand('<abuf>')), 'updatetime_backup', &updatetime) |
        \ let &updatetime = float2nr(g:esearch#backend#vimproc#updatetime)

  au BufUnload <buffer>
        \ call esearch#backend#vimproc#abort(str2nr(expand('<abuf>')))
endfu


function! esearch#backend#vimproc#sid() abort
  return maparg('<SID>', 'n')
endfunction
function! esearch#backend#vimproc#scope() abort
  return s:
endfunction
nnoremap <SID>  <SID>
