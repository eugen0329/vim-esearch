let s:jobs = {}

if !exists('g:esearch#backend#nvim#ticks')
  let g:esearch#backend#nvim#ticks = 3
endif

fu! esearch#backend#nvim#init(cmd, pty) abort
  let job_id = jobstart(['sh', '-c', a:cmd], {
          \ 'on_stdout': function('s:stdout'),
          \ 'on_stderr': function('s:stderr'),
          \ 'on_exit':   function('s:exit'),
          \ 'pty': a:pty,
          \ 'tick': 0,
          \ 'ticks': g:esearch#backend#nvim#ticks,
          \ })
  call jobclose(job_id, 'stdin')

  let request = {
        \ 'job_id':   job_id,
        \ 'finished':   0,
        \ 'backend': 'nvim',
        \ 'command': a:cmd,
        \ 'data': [],
        \ 'events': {
        \   'finish': 'ESearchNVimFinish'.job_id,
        \   'update': 'ESearchNVimUpdate'.job_id
        \ }
        \}
  let s:jobs[job_id] = { 'data': [], 'request': request }

  return request
endfu

" TODO encoding
fu! s:stdout(job_id, data, event) abort
  let job = s:jobs[a:job_id]
  let data = a:data

  " Parse data
  if !empty(data) && !empty(job.request.data)
    let job.request.data[-1] .= data[0]
    call remove(data, 0)
  endif
  " call esearch#out#{b:esearch.out}#merge_data()
  if self.pty
    call map(data, "substitute(v:val, '\\r$', '', '')")
  endif
  let data = filter(data, '"" !=# v:val')
  let job.request.data += data

  " Reduce buffer updates to prevent long cursor lock
  let self.tick = self.tick + 1
  if self.tick % self.ticks == 1
    " call esearch#out#{b:esearch.out}#update()
    exe 'doau User '.job.request.events.update
  endif
endfu

fu! s:stderr(job_id, data, event)
  let job = s:jobs[a:job_id]
  let data = a:data
  if !has_key(job.request, 'errors')
    let job.request.errors = []
  endif

  if !empty(data) && data[0] !=# "\n" && !empty(job.request.errors)
    let job.request.errors[-1] .= data[0]
    call remove(data, 0)
  endif
  let job.request.errors += filter(data, '"" !=# v:val')
endfu

fu! s:exit(job_id, status, event)
  let job = s:jobs[a:job_id]
  let job.request.finished = 1
  let job.request.status = a:status
  exe 'doau User '.job.request.events.finish
endfu

" TODO write expansion for commands
" g:esearch.expand_special has no affect due to josbstart is a function
" (e.g #dispatch uses cmdline, where #,%,... can be expanded)
fu! esearch#backend#nvim#escape_cmd(cmd)
  return string(a:cmd)
endfu

fu! esearch#backend#nvim#init_events() abort
  au BufUnload <buffer> call s:abort_job(str2nr(expand('<abuf>')))
endfu

fu! s:abort_job(buf)
  call jobstop(getbufvar(a:buf, 'esearch').request.job_id)
endfu

fu! esearch#backend#nvim#events(request)
  let id = a:request.job_id
endfu
