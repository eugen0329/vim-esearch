let s:jobs = {}

if !exists('g:esearch#backend#nvim#ticks')
  let g:esearch#backend#nvim#ticks = 3
endif

let s:NVIM_JOB_IS_INVALID = -3

fu! esearch#backend#nvim#init(cwd, adapter, command) abort
  let request = {
        \ 'jobstart_args': {
        \   'command': split(&shell) + split(&shellcmdflag) + [a:command],
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
        \ 'adapter':  a:adapter,
        \ 'command':  a:command,
        \ 'cwd':      a:cwd,
        \ 'data':     [],
        \ 'intermediate': '',
        \ 'is_consumed': function('<SID>is_consumed'),
        \ 'errors':     [],
        \ 'finished': 0,
        \ 'status': 0,
        \ 'cursor': 0,
        \ 'async': 1,
        \ 'aborted': 0,
        \ 'events': {
        \   'schedule_finish': 0,
        \   'update': 0
        \ }
        \}

  return request
endfu

fu! esearch#backend#nvim#exec(request) abort
  let cwd = esearch#win#lcd(a:request.cwd)
  try
    let job_id = jobstart(a:request.jobstart_args.command, a:request.jobstart_args.opts)
    let a:request.job_id = job_id
    let a:request.start_at = reltime()
    call jobclose(job_id, 'stdin')
    let s:jobs[job_id] = { 'data': [], 'request': a:request }
  finally
    call cwd.restore()
  endtry
endfu

fu! s:is_consumed() abort dict
  let timeout = max([g:esearch.early_finish_wait - float2nr(reltimefloat(reltime(self.start_at)) * 1000), 1])
  return jobwait([self.job_id], timeout)[0] ==# -1 && self.finished
endfu

" TODO encoding
fu! s:stdout(job_id, data, event) dict abort
  let request = s:jobs[a:job_id].request

  if !empty(request.intermediate)
    let a:data[0] = request.intermediate . a:data[0]
    let request.intermediate = ''
  endif
  let request.intermediate = remove(a:data, -1)
  call extend(request.data, a:data)

  " Reduce buffer updates to prevent long cursor lock
  let self.tick = self.tick + 1
  if self.tick % self.ticks == 1 && !empty(request.events.update)
    call request.events.update()
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
  let errors = filter(data, "'' !=# v:val")
  let job.request.errors += errors
  if empty(errors) | return | endif

  call esearch#stderr#incremental(job.request.adapter, errors)
endfu

fu! s:exit(job_id, status, event) abort
  let job = s:jobs[a:job_id]
  let job.request.finished = 1
  let job.request.status = a:status
  if !job.request.aborted && !empty(job.request.events.schedule_finish)
    call job.request.events.schedule_finish()
  endif
endfu

" TODO write expansion for commands
" g:esearch.expand_special has no affect due to josbstart is a function
" (e.g #dispatch uses cmdline, where #,%,... can be expanded)
fu! esearch#backend#nvim#escape_cmd(command) abort
  return shellescape(a:command)
endfu

fu! esearch#backend#nvim#init_events() abort
  au BufUnload <buffer>
        \ call esearch#backend#nvim#abort(str2nr(expand('<abuf>')))
endfu

fu! esearch#backend#nvim#abort(bufnr) abort
  " FIXME unify with out#qflist
  let esearch = getbufvar(a:bufnr, 'esearch', get(g:, 'esearch_qf', {'request': {}}))
  if empty(esearch.request) || esearch.request.aborted | return | endif
  let esearch.request.aborted = 1

  if has_key(esearch.request, 'job_id') && jobwait([esearch.request.job_id], 0) != [s:NVIM_JOB_IS_INVALID]
    try
      call jobstop(esearch.request.job_id)
    catch /E900:/
      " E900: Invalid job id
    endtry
  endif
endfu
