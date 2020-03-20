fu! esearch#backend#system#init(adapter, cmd, pty) abort
  let request = {
        \ 'command': a:cmd,
        \ 'adapter':  a:adapter,
        \ 'errors': [],
        \ 'async': 0,
        \ 'status': 0,
        \ 'finished': 1
        \}

  return request
endfu

fu! esearch#backend#system#run(request) abort
  let a:request.data = split(system(a:request.command), "\n")
  let a:request.status = v:shell_error

  if a:request.status !=# 0
    let a:request.errors = a:request.data
    call esearch#stderr#incremental(a:request.adapter, a:request.errors)
    redraw!
  endif
endfu

fu! esearch#backend#system#escape_cmd(cmd) abort
  return shellescape(a:cmd)
endfu

fu! esearch#backend#system#abort(...) abort
  " dummy function to meet the api
endfu

fu! esearch#backend#system#init_events() abort
  " dummy function to meet the api
endfu
