if !exists('g:esearch#backend#nvim#ticks')
  let g:esearch#backend#nvim#ticks = 3
endif
 " Rg 13 requires stdin to be closed, but g:esearch.paths can contain #xargs
 " where a pipe is used. TODO improve esearch#backend#{}#init interface
let s:CLOSE_STDIN = g:esearch#has#posix_shell ? ' 0<&-' : ''
let s:NVIM_JOB_IS_INVALID = -3
let s:jobs = {}

fu! esearch#backend#nvim#init(cwd, adapter, command, ...) abort
  let is_xargs = get(a:000, 0)
  let request = {
        \ 'jobstart_args': {
        \   'command': split(&shell) + split(&shellcmdflag) + [a:command . (is_xargs ? '' : s:CLOSE_STDIN)],
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
        \ 'cb': {
        \   'finish': 0,
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

fu! s:is_consumed(wait) abort dict
  let timeout = a:wait - float2nr(reltimefloat(reltime(self.start_at)) * 1000)
  if timeout < 0.0 | return 0 | endif
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
  if self.tick % self.ticks == 1 && !empty(request.cb.update)
    call request.cb.update()
  endif
endfu

" Same chunking as in s:stdout: the first item continues the last line of the
" previous chunk, the last item is an incomplete line.
fu! s:stderr(job_id, data, event) dict abort
  let request = s:jobs[a:job_id].request
  if !has_key(request, 'errors') | let request.errors = [] | endif

  let data = a:data
  let data[0] = get(request, 'stderr_intermediate', '') . data[0]
  let request.stderr_intermediate = remove(data, -1)
  let errors = filter(data, "'' !=# v:val")
  if empty(errors) | return | endif

  let request.errors += errors
  call esearch#stderr#incremental(request.adapter, errors)
endfu

fu! s:exit(job_id, status, event) abort
  let job = s:jobs[a:job_id]
  let job.request.finished = 1
  let job.request.status = a:status
  " flush the last stderr line without a trailing newline
  if !empty(get(job.request, 'stderr_intermediate', ''))
    let job.request.errors += [job.request.stderr_intermediate]
    call esearch#stderr#incremental(job.request.adapter, [job.request.stderr_intermediate])
    let job.request.stderr_intermediate = ''
  endif
  if !job.request.aborted && !empty(job.request.cb.finish)
    call job.request.cb.finish()
  endif
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
