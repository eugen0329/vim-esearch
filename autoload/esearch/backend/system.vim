fu! esearch#backend#system#init(cmd, pty) abort
  let request = {
        \ 'data': split(system(a:cmd), "\n"),
        \ 'errors': [],
        \ 'async': 0,
        \ 'status': 0,
        \ 'finished': 1
        \}

  return request
endfu

fu! esearch#backend#system#escape_cmd(cmd) abort
  return esearch#util#shellescape(a:cmd)
endfu

fu! esearch#backend#system#abort(...) abort
  " dummy function to meet the api
endfu

fu! esearch#backend#system#init_events() abort
  " dummy function to meet the api
endfu
