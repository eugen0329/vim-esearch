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

" TODO decouple consuming of data from pipe and output updation processes

fu! esearch#backend#vimproc#init(cwd, adapter, cmd) abort
  let request = {
        \ 'internal_id': s:incrementable_internal_id,
        \ 'format': '%f:%l:%c:%m,%f:%l:%m',
        \ 'backend': 'vimproc',
        \ 'adapter': a:adapter,
        \ 'command': a:cmd,
        \ 'cwd': a:cwd,
        \ 'data': [],
        \ 'errors': [],
        \ 'async': 1,
        \ 'status': 0,
        \ 'finished': 0,
        \ 'aborted': 0,
        \ '_last_update_time':   esearch#util#timenow(),
        \ 'events': {
        \   'finish':            0,
        \   'update':            0,
        \   'trigger_key_press': 0
        \ }
        \}

  let s:requests[s:incrementable_internal_id] = request
  let s:incrementable_internal_id += 1

  return request
endfu

fu! esearch#backend#vimproc#run(request) abort
  let original_cwd = esearch#util#lcd(a:request.cwd)
  try
    let pipe = vimproc#popen3(
          \ vimproc#util#iconv(a:request.command, &encoding, 'char'))
    call pipe.stdin.close()

    let a:request.pipe = pipe

    " TODO should not be within the adapter
    exe 'aug ESearchVimproc'.a:request.internal_id
      au!
      exe 'au CursorMoved * call s:_on_cursor_moved('.a:request.internal_id.')'
      exe 'au CursorHold  * call s:_on_cursor_hold('. a:request.internal_id.')'
    aug END
  finally
    call original_cwd.restore()
  endtry
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
    call esearch#stderr#incremental(a:request.adapter, errors)
  endif
endfu

fu! s:_on_cursor_moved(request_id) abort
  let request = s:requests[a:request_id]

  if esearch#util#timenow() < &updatetime/1000.0 + request._last_update_time
    return -1
  endif

  call s:read_data(request)
  if !request.aborted && !empty(request.events.update)
    call request.events.update()
  endif
  let request._last_update_time = esearch#util#timenow()

  if request.pipe.stdout.eof
    let request.finished = 1
  endif

  if s:completed(request)
    call s:finish(request, a:request_id)
  endif
endfu

fu! s:finish(request, request_id) abort
  call s:read_errors(a:request)
  if has_key(a:request, 'bufnr') && a:request.bufnr
    let updatetime_backup = getbufvar(a:request.bufnr, 'updatetime_backup')
    if !empty(updatetime_backup)
      " TODO can be blank for qf, have to be inspected
      call setbufvar(a:request.bufnr, '&updatetime', float2nr(updatetime_backup))
    endif
  endif
  let [a:request.cond, a:request.status] = a:request.pipe.waitpid()
  let a:request.finished = 1
  if !a:request.aborted && !empty(a:request.events.finish)
    call a:request.events.finish()
  endif
  exe 'au! ESearchVimproc'.a:request_id
endfu

fu! s:_on_cursor_hold(request_id) abort
  let request = s:requests[a:request_id]
  call s:read_data(request)

  let events = request.events
  if !request.aborted && !empty(request.events.update)
    call request.events.update()
  endif
  let request._last_update_time = esearch#util#timenow()

  if request.pipe.stdout.eof
    let request.finished = 1
  endif

  if s:completed(request)
    call s:finish(request, a:request_id)
  elseif !empty(events.trigger_key_press)
    call events.trigger_key_press()
  endif
endfu

fu! s:read_data(request) abort
  let request = a:request
  let data = request.pipe.stdout.read_lines(-1, g:esearch#backend#vimproc#read_timeout)
  let request.data += data
endfu

fu! s:completed(request) abort
  return a:request.pipe.stdout.eof
        \ && (!has_key(a:request, 'out_finish') || a:request.out_finish())
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
