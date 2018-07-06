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
if !exists('g:esearch#backend#vim8#timer')
  " TODO better name
  let g:esearch#backend#vim8#timer = 1000
endif

fu! esearch#backend#vim8#init(cmd, pty) abort
  " TODO add 'stoponexit'
  let request = {
        \ 'internal_job_id': s:incrementable_internal_id,
        \ 'old_data_ptr': '',
        \ 'jobstart_args': {
        \   'cmd': [&shell, &shellcmdflag, a:cmd],
        \   'opts': {
        \     'out_cb': function('s:stdout', [s:incrementable_internal_id]),
        \     'err_cb': function('s:stderr', [s:incrementable_internal_id]),
        \     'exit_cb': function('s:exit', [s:incrementable_internal_id]),
        \     'close_cb': function('s:closed', [s:incrementable_internal_id]),
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
endfu

fu! s:stderr(job_id, job, data) abort
  let job = s:jobs[a:job_id]
  let data = split(a:data, "\n", 1)
  if !has_key(job.request, 'errors')
    let job.request.errors = []
  endif

  let job.request.errors += filter(data, "'' !=# v:val")
endfu

func! s:timer_stop_workaround(job, timer) abort
  " smh timer_stop cannot stop timer within a callback
  call timer_stop(a:job.request.timer_id)
endfunc

func! s:watch_for_buffered_data_render_complete(job, timer) abort
  " dirty check
  if a:job.request.data_ptr == a:job.request.old_data_ptr
    exe 'do User '.a:job.request.events.forced_finish
    call timer_start(0, function('s:timer_stop_workaround', [a:job]))
  else
    let a:job.request.old_data_ptr = a:job.request.data_ptr
  endif
endfunc

fu! s:closed(job_id, channel) abort
  let job = s:jobs[a:job_id]
  let job.request.finished = 1

  " TODO should be properly tested first
  if esearch#util#vim8_calls_close_cb_last()
    exe 'do User '.job.request.events.forced_finish
  else
    let job.request.timer_id = timer_start(g:esearch#backend#vim8#timer,
          \ function('s:watch_for_buffered_data_render_complete', [job]),
          \ {'repeat': -1})
  endif
endfu

fu! s:exit(job_id, job, status) abort
  let job = s:jobs[a:job_id]
  let job.request.status = a:status
endfu

" TODO write expansion for commands
" g:esearch.expand_special has no affect due to josbstart is a function
" (e.g #dispatch uses cmdline, where #,%,... can be expanded)
fu! esearch#backend#vim8#escape_cmd(cmd) abort
  return shellescape(a:cmd)
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

  if has_key(esearch.request, 'timer_id')
    call timer_stop(esearch.request.timer_id)
  endif

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
