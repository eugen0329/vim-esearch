fu! esearch#backend#system#init(cmd, pty) abort
  let request = {
        \ 'command': a:cmd,
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
