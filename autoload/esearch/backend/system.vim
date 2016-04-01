fu! esearch#backend#system#init(cmd, pty) abort
  let request = {
        \ 'data': split(system(a:cmd), "\n"),
        \ 'async': 0,
        \}

  return request
endfu


fu! esearch#backend#system#escape_cmd(cmd)
  return esearch#util#shellescape(a:cmd)
endfu

fu! esearch#backend#system#init_events()
endfu
