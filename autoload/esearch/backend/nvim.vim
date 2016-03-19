let s:jobs = {}

fu! esearch#backend#nvim#init(cmd) abort
  let job_id = jobstart(a:cmd, {
          \ 'on_stdout' : function('s:job_handler'),
          \ 'on_stderr' : function('s:job_handler'),
          \ 'on_exit' : function('s:job_handler'),
          \ 'pty' : 0,
          \ })

  let request = {
        \ 'job_id':   job_id,
        \ 'finished':   0,
        \ 'backend': 'nvim',
        \ 'parts': []
        \}
  let s:jobs[job_id] = { 'data': [], 'request': request }
  return request
endfu

fu! s:job_handler(job_id, data, event) abort
  if !has_key(s:jobs, a:job_id)
  endif
  let job = s:jobs[a:job_id]
  let data = a:data

  if a:event ==# 'stderr'
    echo 'ERROR'
    return 1
  elseif a:event ==# 'exit'
    let job.request.finished = 1
    return 0
  endif

  if !empty(data) && data[0] !=# "\n" && !empty(job.data)
    let job.data[-1] .= data[0]
    call remove(data, 0)
  endif
  let job.data += filter(a:data, '"" !=# v:val')
endfu


fu! esearch#backend#nvim#data(request) abort
  return s:jobs[a:request.job_id].data
endfu

fu! esearch#backend#nvim#finished(request) abort
  return s:jobs[a:request.job_id].request.finished
endfu
