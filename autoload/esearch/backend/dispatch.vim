fu! esearch#backend#dispatch#init(cmd) abort
  silent exe 'Dispatch! '.a:cmd
  let request = dispatch#request()
  let request.format = '%f:%l:%c:%m,%f:%l:%m'
  let request.background = 1
  let request.backend = 'dispatch'
  return request
endfu

fu! esearch#backend#dispatch#finished(request) abort
  " TODO
  return !b:esearch.handler_running && b:esearch._lines_iterator == len(b:esearch.parsed)
endfu

" Extracted from tpope/dispatch
fu! esearch#backend#dispatch#running(handler, pid) abort
  if empty(a:pid)
    return 0
  elseif exists('*dispatch#'.a:handler.'#running')
    return dispatch#{a:handler}#running(a:pid)
  elseif has('win32')
    let tasklist_cmd = 'tasklist /fi "pid eq '.a:pid.'"'
    if &shellxquote ==# '"'
      let tasklist_cmd = substitute(tasklist_cmd, '"', "'", "g")
    endif
    return system(tasklist_cmd) =~# '==='
  else
    call system('kill -0 '.a:pid)
    return !v:shell_error
  endif
endfu

fu! esearch#backend#dispatch#status() abort
  let request = b:esearch.request
  try
    let status = str2nr(readfile(request.file . '.complete', 1)[0])
  catch
    let status = -1
  endtry
  return status
endfu

fu! esearch#backend#dispatch#data(request) abort
  let request = a:request
  if !filereadable(fnameescape(request.file))
    throw "Can't open file for reading" . request.file
  endif
  let file_content = []

  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  let dir = getcwd()
  try
    exe cd fnameescape(request.directory)
    let file_content = filter(readfile(fnameescape(request.file)), '!empty(v:val)')
  finally
    exe cd fnameescape(dir)
  endtry

  return file_content
endfu
