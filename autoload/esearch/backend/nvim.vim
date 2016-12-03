let s:jobs = {}
let s:incrementable_internal_id = 0

if !exists('g:esearch#backend#nvim#ticks')
  let g:esearch#backend#nvim#ticks = 3
endif

fu! esearch#backend#nvim#init(cmd, pty) abort
  let request = {
        \ 'internal_job_id': s:incrementable_internal_id,
        \ 'jobstart_args': {
        \   'cmd': ['sh', '-c', a:cmd],
        \   'opts': {
        \     'on_stdout': function('s:stdout'),
        \     'on_stderr': function('s:stderr'),
        \     'on_exit':   function('s:exit'),
        \     'pty': 0,
        \     'tick': 0,
        \     'ticks': g:esearch#backend#nvim#ticks,
        \   },
        \ },
        \ 'backend':  'nvim',
        \ 'command':  a:cmd,
        \ 'data':     [],
        \ 'intermediate':     '',
        \ 'errors':     [],
        \ 'finished': 0,
        \ 'status': 0,
        \ 'async': 1,
        \ 'events': {
        \   'forced_finish': 'ESearchNVimFinish'.s:incrementable_internal_id,
        \   'update': 'ESearchNVimUpdate'.s:incrementable_internal_id
        \ }
        \}

  let s:incrementable_internal_id += 1

  return request
endfu

fu! esearch#backend#nvim#run(request) abort
  let job_id = jobstart(a:request.jobstart_args.cmd, a:request.jobstart_args.opts)
  call jobclose(job_id, 'stdin')
  let s:jobs[job_id] = { 'data': [], 'request': a:request }
endfu

" TODO encoding
fu! s:stdout(job_id, data, event) dict abort
  let job = s:jobs[a:job_id]
  let data = a:data

  " If there is incomplete line from the last s:stduout call
  if !empty(job.request.intermediate) && !empty(data)
    let data[0] = job.request.intermediate . data[0]
    let job.request.intermediate = ''
  endif

  " If the last line is incomplete:
  if !empty(data) && data[-1] !~# '\r$'
    let job.request.intermediate = remove(data, -1)
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
        \ call eserach#backend#nvim#abort(str2nr(expand('<abuf>')))
endfu

fu! esearch#backend#nvim#abort(bufnr) abort
  let esearch = getbufvar(a:bufnr, 'esearch', 0)

  if !empty(esearch) && has_key(esearch.request, 'job_id') && jobwait([esearch.request.job_id], 0) != [-3]
    try
      call jobstop(esearch.request.job_id)
    catch /E900:/
      " E900: Invalid job id
    endtry
  endif
endfu
