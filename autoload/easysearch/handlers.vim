fu! easysearch#handlers#cursor_moved()
  if  easysearch#util#timenow() < &updatetime/1000.0 + b:last_update_time
    return -1
  endif

  let qf_entirely_parsed = len(b:qf_file) == b:last_index && b:qf_entirely_parsed
  if !easysearch#util#running(b:request.handler, b:request.pid) && qf_entirely_parsed
    exe 'au! EasysearchAutocommands'
    " let &updatetime = float2nr(s:updatetime_bak)

    call easysearch#util#cgetfile(b:request)
    call easysearch#win#update(1)
  else
    if !easysearch#util#cgetfile(b:request)
      call easysearch#win#update(0)
    endif
  endif
endfu
fu! easysearch#handlers#cursor_hold()
  let qf_entirely_parsed = len(b:qf_file) == b:last_index && b:qf_entirely_parsed
  if !easysearch#util#running(b:request.handler, b:request.pid) && qf_entirely_parsed
    exe 'au! EasysearchAutocommands'
    " let &updatetime = float2nr(s:updatetime_bak)
    let b:request.background = 0

    call easysearch#win#update(1)
  else
    if !easysearch#util#cgetfile(b:request)
      call easysearch#win#update(0)
    endif
    call feedkeys('\<Plug>(easysearch-Nop)')
  endif
endfu
