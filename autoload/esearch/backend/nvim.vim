let s:jobs = {}

fu! esearch#backend#nvim#init(cmd) abort
  let job_id = jobstart(a:cmd, {
          \ 'on_stdout': function('s:stdout'),
          \ 'on_stderr': function('s:stderr'),
          \ 'on_exit':   function('s:exit'),
          \ 'ticks':     g:esearch.ticks,
          \ 'tick':      0,
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

fu! s:stderr(job_id, data, event)
  if !exists('b:esearch')
    return 0
  endif
  let job = s:jobs[a:job_id]
  if !has_key(job.request, 'errors')
    let job.request.errors = []
  endif
  call add(job.request.errors, a:data)
endfu

fu! s:exit(job_id, data, event)
  if !exists('b:esearch')
    return 0
  endif
  let job = s:jobs[a:job_id]
  let job.request.finished = 1
  let s:ignore_batches = 1
  call esearch#out#{b:esearch.out}#update(job.data, s:ignore_batches)
  call esearch#out#{b:esearch.out}#on_finish()
endfu

fu! esearch#backend#nvim#escape_cmd(cmd)
  return a:cmd
endfu

fu! s:stdout(job_id, data, event) abort
  if !exists('b:esearch')
    return 0
  endif

  let job = s:jobs[a:job_id]
  let data = a:data

  " Parse data
  if !empty(data) && data[0] !=# "\n" && !empty(job.data)
    let job.data[-1] .= data[0]
    call remove(data, 0)
  endif
  let job.data += filter(a:data, '"" !=# v:val')

  " Reduce buffer updates to prevent long cursor lock
  let self.tick = self.tick + 1
  if self.tick % self.ticks == 1
    call esearch#out#{b:esearch.out}#update(job.data)
  endif
endfu

fu! esearch#backend#nvim#init_events() abort
  au BufUnload <buffer> call s:abort_job(str2nr(expand('<abuf>')))
endfu

fu! s:abort_job(buf)
  call jobstop(getbufvar(a:buf, 'esearch').request.job_id)
endfu
