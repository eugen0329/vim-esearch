fu! easysearch#handlers#cursor_moved()
  if  easysearch#util#timenow() < &updatetime/1000.0 + b:last_update_time
    return -1
  endif

  let qf_entirely_parsed = len(b:qf_file) == b:last_index && b:qf_entirely_parsed

  if !easysearch#util#cgetfile(b:request)
    call easysearch#win#update()
  endif
  if !easysearch#util#running(b:request.handler, b:request.pid) && qf_entirely_parsed
    call easysearch#handlers#finish()
  endif

endfu

fu! easysearch#handlers#cursor_hold()
  let qf_entirely_parsed = len(b:qf_file) == b:last_index && b:qf_entirely_parsed

  if !easysearch#util#cgetfile(b:request)
    call easysearch#win#update()
  endif

  if !easysearch#util#running(b:request.handler, b:request.pid) && qf_entirely_parsed
    call easysearch#handlers#finish()
  else
    call feedkeys('\<Plug>(easysearch-Nop)')
  endif
endfu

fu! easysearch#handlers#finish()
  au! EasysearchAutocommands
  let &updatetime = float2nr(b:updatetime_backup)

  setlocal noreadonly
  setlocal modifiable
  call setline(1, getline(1) . '. Finished.' )
  call setline(2, '')
  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified
endfu
