let s:job_id_counter = 0

let s:jobs = {}
let s:incrementable_internal_id = 0

if !exists('g:esearch#backend#vim8#ticks')
  let g:esearch#backend#vim8#ticks = 0
endif

fu! esearch#backend#vim8#init(cmd, pty) abort
  let request = {
        \ 'internal_job_id': s:incrementable_internal_id,
        \ 'jobstart_args': {
        \   'cmd': ['sh', '-c', a:cmd],
        \   'opts': {
        \     'out_cb': function('s:stdout', [s:incrementable_internal_id]),
        \     'err_cb': function('s:stderr', [s:incrementable_internal_id]),
        \     'exit_cb': function('s:exit', [s:incrementable_internal_id]),
   \     'in_io': 'null',
   \     'out_mode': 'nl',
        \   },
        \ },
        \ 'tick': 0,
        \ 'ticks': g:esearch#backend#vim8#ticks,
        \ 'backend':  'vim8',
        \ 'command':  a:cmd,
        \ 'data':     [],
        \ 'intermediate':     '',
        \ 'errors':     [],
        \ 'finished': 0,
        \ 'status': 0,
        \ 'async': 1,
        \ 'aborted': 0,
        \ 'cbs': [],
        \ 'events': {
        \   'forced_finish': 'ESearchvim8ForcedFinish'.s:incrementable_internal_id,
        \   'finish': 'ESearchvim8Finish'.s:incrementable_internal_id,
        \   'update': 'ESearchvim8Update'.s:incrementable_internal_id
        \ }
        \}

  let s:incrementable_internal_id += 1

  return request
endfu

fu! esearch#backend#vim8#run(request) abort
  let s:jobs[a:request.internal_job_id] = { 'data': [], 'request': a:request }
  let a:request.job = job_start(a:request.jobstart_args.cmd, a:request.jobstart_args.opts)
endfu

" TODO encoding
fu! s:stdout(job_id, job, data) abort
  let job = s:jobs[a:job_id]
  let data = split(a:data, "\n", 1)

  " If there is incomplete line from the last s:stduout call
  if !empty(job.request.intermediate) && !empty(data)
    let data[0] = job.request.intermediate . data[0]
    let job.request.intermediate = ''
  endif

  " let data = filter(data, "'' !=# v:val")

  " let status = job_info(job.request.job).status
" || (!empty(status) && status ==# 'dead')
  " if data[-1] ==# 'DETACH'
  "   call remove(data, -1)
  "   let detach = 1
  " else
  "   let detach = 0
  " endif

  let job.request.data += data

  " Reduce buffer updates to prevent long cursor lock
  let job.request.tick = job.request.tick + 1
  " let g:detach = detach
  if job.request.tick % job.request.ticks == 1
 " || detach
    " exe 'do User '.job.request.events.update
    call job.request.cbs[0](job.request.esearch)
    " exe 'do User '.job.request.events.update
  endif

  " if detach
  "   call s:exit(a:job_id, a:job, 0)
  " endif
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
  if job.request.finished ==# 1 | return | endif

  " exe 'do User '.job.request.events.update

  let job.request.finished = 1
  let job.request.status = a:status
  if !job.request.aborted
    call job.request.cbs[-1](job.request.esearch)
    " exe 'do User '.job.request.events.finish
  endif
endfu

" TODO write expansion for commands
" g:esearch.expand_special has no affect due to josbstart is a function
" (e.g #dispatch uses cmdline, where #,%,... can be expanded)
fu! esearch#backend#vim8#escape_cmd(cmd) abort
  let cmd = escape(esearch#util#shellescape(a:cmd), '()')
  let cmd = substitute(cmd, '>', '\\>', 'g')
  let cmd = substitute(cmd, '&', '\\&', 'g')
  return cmd
endfu

fu! esearch#backend#vim8#init_events() abort
  au BufUnload <buffer>
        \ call esearch#backend#vim8#abort(str2nr(expand('<abuf>')))
endfu

fu! esearch#backend#vim8#abort(bufnr) abort
  return
  " FIXME unify with out#qflist
  let esearch = getbufvar(a:bufnr, 'esearch', get(g:, 'esearch_qf', {'request': {}}))
  let esearch.request.aborted = 1

  if !empty(esearch) && has_key(esearch.request, 'job_id') && jobwait([esearch.request.job_id], 0) != [-3]
    try
      call jobstop(esearch.request.job_id)
    catch /E900:/
      " E900: Invalid job id
    endtry
  endif
endfu

function! esearch#backend#vim8#_context() abort
  return s:
endfunction
function! esearch#backend#vim8#_sid() abort
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
