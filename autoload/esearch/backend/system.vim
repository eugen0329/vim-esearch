fu! esearch#backend#system#init(cwd, adapter, cmd) abort
  let request = {
        \ 'command': a:cmd,
        \ 'cwd':     a:cwd,
        \ 'adapter':  a:adapter,
        \ 'data':   [],
        \ 'errors': [],
        \ 'is_consumed': function('<SID>is_consumed'),
        \ 'async': 0,
        \ 'cursor': 0,
        \ 'status': 0,
        \ 'finished': 0,
        \ 'cb': {},
        \}

  return request
endfu

fu! s:is_consumed(wait) abort dict
  return self.finished
endfu

fu! esearch#backend#system#exec(request) abort
  let cwd = esearch#win#lcd(a:request.cwd)
  try
    let a:request.data = split(system(a:request.command), '\r\=\n')
    let a:request.status = v:shell_error
    let a:request.finished = 1

    if a:request.status !=# 0
      let a:request.errors = a:request.data
      call esearch#stderr#incremental(a:request.adapter, a:request.errors)
      redraw!
    endif
  finally
    call cwd.restore()
  endtry
endfu

fu! esearch#backend#system#abort(...) abort
endfu
