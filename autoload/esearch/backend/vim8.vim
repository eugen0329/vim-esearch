let s:jobs = {}

if !exists('g:esearch#backend#vim8#ticks')
  let g:esearch#backend#vim8#ticks = 100
endif

let s:job_id_counter = 0

let s:jobs = {}
let s:incrementable_internal_id = 0

if !exists('g:esearch#backend#vim8#ticks')
  let g:esearch#backend#vim8#ticks = 3
endif

fu! esearch#backend#vim8#init(cmd, pty) abort
  let request = {
        \ 'internal_job_id': s:incrementable_internal_id,
        \ 'jobstart_args': {
        \   'cmd': ['sh', '-c', a:cmd],
        \   'opts': {
        \     'out_cb': function('s:stdout', [s:incrementable_internal_id]),
        \     'err_cb': function('s:stderr', [s:incrementable_internal_id]),
        \     'in_io': 'null',
        \   },
        \ },
        \ 'tick': 0,
        \ 'ticks': g:esearch#backend#vim8#ticks,
        \ 'backend':  'vim8',
        \ 'command':  a:cmd,
        \ 'data':     [],
        \ 'errors':     [],
        \ 'finished': 0,
        \ 'status': 0,
        \ 'async': 1,
        \ 'aborted': 0,
        \ 'events': {
        \   'forced_finish': 'ESearchvim8Finish'.s:incrementable_internal_id,
        \   'update': 'ESearchvim8Update'.s:incrementable_internal_id
        \ }
        \}

  let s:incrementable_internal_id += 1

  return request
endfu

fu! esearch#backend#vim8#run(request) abort
  let s:jobs[a:request.internal_job_id] = { 'data': [], 'request': a:request }
  let a:request.job_id = job_start(a:request.jobstart_args.cmd, a:request.jobstart_args.opts)
endfu

" TODO encoding
fu! s:stdout(job_id, job, data) abort
  let job = s:jobs[a:job_id]
  " as callback can still be triggered with buffered data
  if job.request.aborted | return | endif

  let data = split(a:data, "\n", 1)
  let job.request.data += filter(data, "'' !=# v:val")

  " Reduce buffer updates to prevent long cursor lock
  let job.request.tick = job.request.tick + 1
  if job.request.tick % job.request.ticks == 1
    exe 'do User '.job.request.events.update
  endif

  if ch_info(job.request.job_id).out_status ==# 'closed'
    call s:exit(a:job_id, a:job, 0)
  endif
endfu

fu! s:stderr(job_id, job, data) abort
  let job = s:jobs[a:job_id]
  let data = split(a:data, "\n", 1)
  if !has_key(job.request, 'errors')
    let job.request.errors = []
  endif

  if !empty(data) && data[0] !=# "\n" && !empty(job.request.errors)
    let job.request.errors[-1] .= data[0]
    call remove(data, 0)
  endif
  let job.request.errors += filter(data, "'' !=# v:val")
endfu

fu! s:exit(job_id, job, status) abort
  let job = s:jobs[a:job_id]
  if job.request.finished || job.request.aborted | return | endif
  let job.request.finished = 1
  let job.request.status = a:status

  exe 'do User '.job.request.events.forced_finish
endfu

" TODO write expansion for commands
fu! esearch#backend#vim8#escape_cmd(cmd) abort
  let cmd = shellescape(a:cmd)
  return cmd
endfu

fu! esearch#backend#vim8#init_events() abort
  au BufUnload <buffer>
        \ call esearch#backend#vim8#abort(str2nr(expand('<abuf>')))
endfu

fu! esearch#backend#vim8#abort(bufnr) abort
  " FIXME unify with out#qflist
  let esearch = getbufvar(a:bufnr, 'esearch', get(g:, 'esearch_qf', {'request': {}}))
  if empty(esearch)
    return -1
  endif
  let esearch.request.aborted = 1

  if has_key(esearch.request, 'job_id') && job_status(esearch.request.job_id) ==# 'run'
    call ch_close(esearch.request.job_id)
    return job_stop(esearch.request.job_id, "kill")
  endif
endfu

function! esearch#backend#vim8#_context() abort
  return s:
endfunction
function! esearch#backend#vim8#_sid() abort
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
