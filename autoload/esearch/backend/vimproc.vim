if !exists('g:esearch#backend#vimproc#updatetime')
  let g:esearch#backend#vimproc#updatetime = 300.0
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
        \}

  return request
endfu

fu! s:read_data() abort
  let request = b:esearch.request
  let pipe = request.pipe

  let stderr = pipe.stderr
  if !stderr.eof
    let errors = filter(
          \ stderr.read_lines(-1, b:esearch.batch_size), "v:val !~ '^\\s*$'")
    if !empty(errors)
      let b:esearch.request.errors += errors
    endif
  endif

  let stdout = pipe.stdout

  let data = stdout.read_lines(-1, b:esearch.batch_size)
  let request.data += data

  if stdout.eof
    " let [request.cond, request.status] = pipe.waitpid()
  endif
endfu

" TODO write better errors handling
" fu! s:stderr()
"   let pipe = b:esearch.request.pipe

"   if cond ==# 'error' || status !=# 0
"     let b:esearch.request.errors = b:esearch.unparsed + b:esearch.parsed
"     return 1
"   endif

"   return 0
" endfu

fu! esearch#backend#vimproc#escape_cmd(cmd)
  return esearch#util#shellescape(a:cmd)
endfu

function! s:running(finish) abort
  return readfile(a:finish)[0] ==# '1'
endfunction

fu! s:_on_cursor_moved() abort
  if esearch#util#timenow() < &updatetime/1000.0 + b:esearch._last_update_time
    return -1
  endif

  call s:read_data()
  call esearch#out#{b:esearch.out}#update()

  if s:completed(b:esearch.request.data)
    let &updatetime = float2nr(b:updatetime_backup)
    call esearch#out#{b:esearch.out}#on_finish()
  endif
endfu

fu! s:_on_cursor_hold()
  call s:read_data()
  call esearch#out#{b:esearch.out}#update()

  if s:completed(b:esearch.request.data)
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
  let nparsed = b:esearch._lines_iterator
  let eof = b:esearch.request.pipe.stdout.eof
  return eof && b:esearch._lines_iterator == len(b:esearch.parsed)
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
