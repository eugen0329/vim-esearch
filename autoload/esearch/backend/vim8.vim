let s:jobs = {}

if !exists('g:esearch#backend#vim8#ticks')
  let g:esearch#backend#vim8#ticks = 3
endif

let s:job_id_counter = 0


fu! esearch#backend#vim8#init(cmd, pty) abort
  let job_id = s:job_id_counter
  let s:job_id_counter += 1

  let job =  job_start(['sh', '-c', a:cmd], {
          \ 'out_cb':   {job,data->s:stdout(job_id, split(data, "\n"), 'stdout')},
          \ 'err_cb':     {job,data->s:stderr(job_id, split(data, "\n"), 'stderr')},
          \ 'exit_cb':    {job,status->s:exit(job_id, status, 'exit')},
          \ 'mode': 'raw',
          \ 'in_io': 'null',
          \ })

  let request = {
        \ 'job_id':   job_id,
        \ 'job':      job,
        \ 'backend':  'vim8',
        \ 'command':  a:cmd,
        \ 'data':     [],
        \ 'intermediate':     '',
        \ 'errors':     [],
        \ 'finished': 0,
        \ 'status': 0,
        \ 'async': 1,
        \ 'events': {
        \   'forced_finish': 'ESearchVim8Finish'.job_id,
        \   'update': 'ESearchVim8Update'.job_id
        \ }
        \}
  let s:jobs[job_id] = { 'data': [], 'request': request }

  return request
endfu

let g:data =  []

" TODO encoding
fu! s:stdout(job_id, data, event)  abort
  let job = s:jobs[a:job_id]
  let data = a:data

  call add(g:data, data)

  " If there is incomplete line from the last s:stduout call
  if !empty(job.request.intermediate) && !empty(data)
    let data[0] = job.request.intermediate . data[0]
    let job.request.intermediate = ''
  endif

  " If the last line is incomplete:
  if !empty(data) && data[-1] !~# '\r$'
    let job.request.intermediate = remove(data, -1)
  endif

  " if self.pty
    " call map(data, "substitute(v:val, '\\r$', '', '')")
  " endif
  let data = filter(data, "'' !=# v:val")
  let job.request.data += data

  " Reduce buffer updates to prevent long cursor lock
  " let self.tick = self.tick + 1
  " if self.tick % self.ticks == 1
    exe 'do User '.job.request.events.update
  " endif
endfu

fu! s:stderr(job_id, data, event)  abort
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
  " let job.request.finished = 1
  " let job.request.status = a:status
  exe 'do User '.job.request.events.forced_finish
endfu

" TODO write expansion for commands
" g:esearch.expand_special has no affect due to josbstart is a function
" (e.g #dispatch uses cmdline, where #,%,... can be expanded)
fu! esearch#backend#vim8#escape_cmd(cmd) abort
  return escape(esearch#util#shellescape(a:cmd), '()')
endfu

fu! esearch#backend#vim8#init_events() abort
  au BufUnload <buffer>
        \ call eserach#backend#vim8#abort(str2nr(expand('<abuf>')))
endfu

" fu! esearch#backend#vim8#abort(request) abort
"   return jobstop(a:request.job_id)
" endfu
fu! esearch#backend#vim8#abort(bufnr) abort
  let esearch = getbufvar(a:bufnr, 'esearch', 0)

 " && jobwait([esearch.request.job_id], 0) != [-3]
  if !empty(esearch) && has_key(esearch.request, 'job')
    try
      call job_stop(esearch.request.job)
    catch /E900:/
      " E900: Invalid job id
    endtry
  endif
endfu
