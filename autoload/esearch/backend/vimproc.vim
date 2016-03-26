if !exists('g:esearch#backend#vimproc#updatetime')
  let g:esearch#backend#vimproc#updatetime = 300.0
endif

fu! esearch#backend#vimproc#init(cmd) abort
  let pipe = vimproc#popen2(
        \ vimproc#util#iconv(a:cmd, &encoding, 'char'), 1)
  call pipe.stdin.close()

  let request = {
        \ 'format': '%f:%l:%c:%m,%f:%l:%m',
        \ 'backend': 'vimproc',
        \ 'pipe': pipe
        \}

  return request
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

fu! s:stdout() abort
  let pipe = b:esearch.request.pipe

  let candidates = filter(
        \ pipe.stdout.read_lines(-1, b:esearch.batch_size), "v:val !~ '^\\s*$'")

  return filter(candidates, '!empty(v:val)')
endfu

" TODO write better errors handling
fu! s:stderr()
  let pipe = b:esearch.request.pipe

  let [cond, status] = pipe.waitpid()
  if cond ==# 'error' || status !=# 0
    let b:esearch.request.errors = b:esearch.unparsed + b:esearch.parsed
    return 1
  endif

  return 0
endfu

fu! esearch#backend#vimproc#escape_cmd(cmd)
  return esearch#util#shellescape(a:cmd)
endfu

function! s:running(finish) abort
  return readfile(a:finish)[0] ==# '1'
endfunction


" TODO
fu! s:completed(data)
  let nparsed = b:esearch._lines_iterator

  " let handler_running = s:running(b:esearch.request.handler, b:esearch.request.pid)
  let eof = b:esearch.request.pipe.stdout.eof

  return eof && b:esearch._lines_iterator == len(b:esearch.parsed)
endfu

fu! s:_on_cursor_moved() abort
  if esearch#util#timenow() < &updatetime/1000.0 + b:esearch._last_update_time
    return -1
  endif
  let data = s:stdout()

  call esearch#out#{b:esearch.out}#update(data)
  if s:completed(data)
    call s:stderr()

    let &updatetime = float2nr(b:updatetime_backup)
    call esearch#out#{b:esearch.out}#on_finish()
  endif
endfu

fu! s:_on_cursor_hold()
  let data = s:stdout()
  call esearch#out#{b:esearch.out}#update(data)

  if s:completed(data)
    call s:stderr()
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
