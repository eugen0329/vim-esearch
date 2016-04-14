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
        \ 'backend':  'nvim',
        \ 'command':  a:cmd,
        \ 'data':     [],
        \ 'errors':     [],
        \ 'finished': 0,
        \ 'status': 0,
        \ 'async': 1,
        \ 'events': {
        \   'forced_finish': 'ESearchNVimFinish'.job_id,
        \   'update': 'ESearchNVimUpdate'.job_id
        \ }
        \}
  let s:jobs[job_id] = { 'data': [], 'request': request }

  return request
endfu

" TODO encoding
fu! s:stdout(job_id, data, event) dict abort
  let job = s:jobs[a:job_id]
  let data = a:data

  " Parse data
  if !empty(data) && !empty(job.request.data)
    let job.request.data[-1] .= data[0]
    call remove(data, 0)
  endif

  if self.pty
    call map(data, "substitute(v:val, '\\r$', '', '')")
  endif
  let data = filter(data, "'' !=# v:val")
  let job.request.data += data

  " Reduce buffer updates to prevent long cursor lock
  let self.tick = self.tick + 1
  if self.tick % self.ticks == 1
    exe 'do User '.job.request.events.update
  endif
endfu

fu! s:stderr(job_id, data, event) dict abort
  let job = s:jobs[a:job_id]
  let data = a:data
  if !has_key(job.request, 'errors')
    let job.request.errors = []
  endif

  if !empty(data) && data[0] !=# "\n" && !empty(job.request.errors)
    let job.request.errors[-1] .= data[0]
    call remove(data, 0)
  endif
  let job.request.errors += filter(data, "'' !=# v:val")
endfu

fu! s:exit(job_id, status, event) abort
  let job = s:jobs[a:job_id]
  let job.request.finished = 1
  let job.request.status = a:status
  exe 'do User '.job.request.events.forced_finish
endfu

" TODO write expansion for commands
" g:esearch.expand_special has no affect due to josbstart is a function
" (e.g #dispatch uses cmdline, where #,%,... can be expanded)
fu! esearch#backend#nvim#escape_cmd(cmd) abort
  return escape(esearch#util#shellescape(a:cmd), '()')
endfu

fu! esearch#backend#nvim#init_events() abort
  au BufUnload <buffer>
        \ call eserach#backend#nvim#abort(getbufvar(str2nr(expand('<abuf>')), 'esearch').request)
endfu

fu! esearch#backend#nvim#abort(request) abort
  return jobstop(a:request.job_id)
endfu
