if !exists('g:esearch#backend#vim8#ticks')
  let g:esearch#backend#vim8#ticks = 3
endif
let s:jobs = {}
let s:id = esearch#util#counter()

fu! esearch#backend#vim8#init(cwd, adapter, command) abort
  " TODO add 'stoponexit'
  let id = s:id.next()
  let request = {
        \ 'internal_job_id': id,
        \ 'job_id': -1,
        \ 'intermediate': '',
        \ 'jobstart_args': {
        \   'command': split(&shell) + split(&shellcmdflag) + [a:command],
        \   'opts': {
        \     'out_cb': function('s:stdout', [id]),
        \     'err_cb': function('s:stderr', [id]),
        \     'exit_cb': function('s:exit', [id]),
        \     'close_cb': function('s:closed', [id]),
        \     'out_mode': 'raw',
        \     'err_mode': 'nl',
        \     'in_io': 'null',
        \   },
        \ },
        \ 'tick': 0,
        \ 'ticks': g:esearch#backend#vim8#ticks,
        \ 'backend': 'vim8',
        \ 'adapter': a:adapter,
        \ 'command': a:command,
        \ 'is_consumed': function('<SID>is_consumed'),
        \ 'cwd': a:cwd,
        \ 'data': [],
        \ 'errors': [],
        \ 'finished': 0,
        \ 'status': 0,
        \ 'async': 1,
        \ 'aborted': 0,
        \ 'cursor': 0,
        \ 'cb': {'finish': 0, 'update': 0}
        \}

  return request
endfu

fu! esearch#backend#vim8#exec(request) abort
  let s:jobs[a:request.internal_job_id] = { 'data': [], 'request': a:request }
  let cwd = esearch#win#lcd(a:request.cwd)
  try
    let a:request.job_id = job_start(a:request.jobstart_args.command, a:request.jobstart_args.opts)
    let a:request.start_at = reltime()
  finally
    call cwd.restore()
  endtry
endfu

" TODO encoding
fu! s:stdout(job_id, job, data) abort
  let request = s:jobs[a:job_id].request

  let data = split(request.intermediate . a:data, "\n", 1)
  let request.intermediate = data[-1]
  let request.data += data[:-2]
  if !empty(request.cb.update) && request.tick % request.ticks == 1 && !request.aborted
    call request.cb.update()
  endif
  let request.tick = request.tick + 1
endfu

" Adapted from vital-Whisky
fu! s:is_consumed(wait) abort dict
  let timeout = a:wait / 1000.0 - reltimefloat(reltime(self.start_at))
  if timeout < 0.0 | return 0 | endif
  let stopped = 0

  let start_time = reltime()
  let job = self.job_id

  while timeout == 0 || timeout > reltimefloat(reltime(start_time))
    let status = job_status(job)
    if status !=# 'run'
      return self.finished
    endif
    sleep 1m
  endwhile

  return self.finished
endfu

fu! s:stderr(job_id, job, data) abort
  let job = s:jobs[a:job_id]
  let job.request.errors += [a:data]
  call esearch#stderr#incremental(job.request.adapter, [a:data])
endfu

fu! s:closed(job_id, channel) abort
  let job = s:jobs[a:job_id]
  let job.request.finished = 1

  if !empty(job.request.cb.finish)
    call job.request.cb.finish()
  endif
endfu

fu! s:exit(job_id, job, status) abort
  let job = s:jobs[a:job_id]
  let job.request.status = a:status
endfu

fu! esearch#backend#vim8#abort(bufnr) abort
  " FIXME unify with out#qflist
  let esearch = getbufvar(a:bufnr, 'esearch', get(g:, 'esearch_qf', {'request': {}}))
  if empty(esearch.request) || esearch.request.aborted | return | endif
  let esearch.request.aborted = 1

  if has_key(esearch.request, 'timer_id')
    call timer_stop(esearch.request.timer_id)
  endif

  if has_key(esearch.request, 'job_id') && job_status(esearch.request.job_id) ==# 'run'
    call ch_close(esearch.request.job_id)
    call job_stop(esearch.request.job_id, 'kill')
  endif
endfu
