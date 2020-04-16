let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

" TODO refactoring
fu! esearch#out#win#update#init(esearch) abort
  " TODO consider to drop ignore batches
  let a:esearch.ignore_batches = 0
  if !a:esearch.request.async | return | endif

  call extend(a:esearch, {
        \ 'last_update_at':          reltime(),
        \ 'updates_timer':           -1,
        \ 'update_with_timer_start': 0,
        \})

  " TODO replace with g:esearch.throttle_wait > 0
  if g:esearch_win_update_using_timer && has('timers')
    let a:esearch.update_with_timer_start = 1

    aug esearch_win_updates
      au! * <buffer>
      call esearch#backend#{a:esearch.backend}#init_events()

      if a:esearch.backend !=# 'vimproc'
        let a:esearch.early_update_limit = a:esearch.batch_size
        " TODO
        for [func_name, event] in items(a:esearch.request.events)
          let a:esearch.request.events[func_name] =
                \ function('s:early_update_backend_cb', [bufnr('%')])
        endfor
      endif

      let a:esearch.updates_timer = timer_start(
            \ g:esearch_win_updates_timer_wait_time,
            \ function('s:update_timer_cb', [a:esearch, bufnr('%')]),
            \ {'repeat': -1})
    aug END
  else
    let a:esearch.update_with_timer_start = 0

    aug esearch_win_updates
      au! * <buffer>
      call esearch#backend#{a:esearch.backend}#init_events()
    aug END
    for [func_name, event] in items(a:esearch.request.events)
      let a:esearch.request.events[func_name] = function('esearch#out#win#update#' . func_name, [bufnr('%')])
    endfor
  endif
endfu

fu! esearch#out#win#update#uninit(esearch) abort
  if has_key(a:esearch, 'updates_timer')
    call timer_stop(a:esearch.updates_timer)
  endif
endfu

" When checking for an ability to finish early it's important to allow loading more
" data than during early update, as is_consumed() is done using jobwait, that can
" cause unwanted idle when early_update_limit is exceeded, but the backend
" is still working.
fu! esearch#out#win#update#can_finish_early(esearch) abort
  if !a:esearch.request.async | return | endif

  let original_early_update_limit = a:esearch.early_update_limit
  let a:esearch.early_update_limit *= 1000
  try
    return a:esearch.request.is_consumed()
          \ && (len(a:esearch.request.data) - a:esearch.request.cursor) <= a:esearch.final_batch_size
  finally
    let a:esearch.early_update_limit = original_early_update_limit
  endtry
endfu

" Is used to render the first batch as soon as possible before the first timer
" callback invokation. Is called on stdout event from a backend and is undloaded
" when the first batch is rendered. Will render <= 2 * batch_size entries
" (usually much less than 2x).
fu! s:early_update_backend_cb(bufnr) abort
  if a:bufnr != bufnr('%')
    return
  endif
  let esearch = getbufvar(a:bufnr, 'esearch')

  if esearch.request.cursor < esearch.early_update_limit
    call esearch#out#win#update#update(a:bufnr)

    if esearch.request.finished && len(esearch.request.data) == esearch.request.cursor
      call esearch#out#win#update#schedule_finish(a:bufnr)
    endif
  else
    call s:unload_update_events(esearch)
  endif
endfu

fu! s:update_timer_cb(esearch, bufnr, timer) abort
  " Timer counts time only from the begin, not from the return, so we have to
  " ensure it manually
  " TODO extract to a separate throttling lib
  let elapsed = reltimefloat(reltime(a:esearch.last_update_at)) * 1000
  if elapsed < g:esearch_win_updates_timer_wait_time
    return
  endif

  call esearch#out#win#update#update(a:esearch.bufnr)

  let request = a:esearch.request
  if request.finished && len(request.data) == request.cursor
    let a:esearch.updates_timer = -1
    call esearch#out#win#update#schedule_finish(a:esearch.bufnr)
    call timer_stop(a:timer)
  endif
endfu

fu! s:unload_update_events(esearch) abort
  aug esearch_win_updates
    for func_name in keys(a:esearch.request.events)
      let a:esearch.request.events[func_name] = s:null
    endfor
  aug END
  exe printf('au! esearch_win_updates * <buffer=%d>', a:esearch.bufnr)
endfu

fu! esearch#out#win#update#update(bufnr, ...) abort
  " prevent updates when outside of the window
  if a:bufnr != bufnr('%')
    return
  endif
  let esearch = getbufvar(a:bufnr, 'esearch')
  let ignore_batches = get(a:000, 0, esearch.ignore_batches)
  let request = esearch.request
  let data = request.data
  let data_size = len(data)

  call setbufvar(a:bufnr, '&ma', 1)
  if data_size > request.cursor
    " TODO consider to discard ignore_batches as it doesn't make a lot of sense
    if ignore_batches
          \ || data_size - request.cursor - 1 <= esearch.batch_size
          \ || (request.finished && data_size - request.cursor - 1 <= esearch.final_batch_size)
      let [from, to] = [request.cursor, data_size - 1]
      let request.cursor = data_size
    else
      let [from, to] = [request.cursor, request.cursor + esearch.batch_size - 1]
      let request.cursor += esearch.batch_size
    endif

    if g:esearch_out_win_render_using_lua
      call esearch#out#win#render#lua#do(a:bufnr, data, from, to, esearch)
    else
      call esearch#out#win#render#viml#do(a:bufnr, data, from, to, esearch)
    endif
  endif

  call esearch#util#setline(a:bufnr, 1, esearch.header_text())

  call setbufvar(a:bufnr, '&modifiable', 0)
  let esearch.last_update_at = reltime()
endfu

fu! esearch#out#win#update#schedule_finish(bufnr) abort
  if a:bufnr == bufnr('%')
    call esearch#out#win#update#finish(a:bufnr)
  else
    " Bind event to finish the search as soon as the buffer is entered
    aug esearch_win_updates
      exe printf('au BufEnter <buffer=%d> ++once call esearch#out#win#update#finish(%d)', a:bufnr, a:bufnr)
    aug END
    return
  endif
endfu

fu! esearch#out#win#update#finish(bufnr) abort
  " prevent updates when outside of the buffer
  if a:bufnr != bufnr('%')
    return
  endif

  call esearch#util#doautocmd('User esearch_win_finish_pre')
  let esearch = getbufvar(a:bufnr, 'esearch')

  call esearch#out#win#update#update(a:bufnr, 1)
  " TODO
  let esearch.contexts[-1].end = line('$')
  if g:esearch_win_results_len_annotations
    call luaeval('esearch.appearance.set_context_len_annotation(_A[1], _A[2])',
          \ [esearch.contexts[-1].begin, len(esearch.contexts[-1].lines)])
  endif

  if esearch.request.async
    exe printf('au! esearch_win_updates * <buffer=%s>', string(a:bufnr))
  endif

  if has_key(esearch, 'updates_timer')
    call timer_stop(esearch.updates_timer)
  endif
  call setbufvar(a:bufnr, '&modifiable', 1)

  if !esearch.current_adapter.is_success(esearch.request)
    call esearch#stderr#finish(esearch)
  endif

  let esearch.header_text = function('esearch#out#win#header#finished_render')
  call esearch#util#setline(a:bufnr, 1, esearch.header_text())

  call setbufvar(a:bufnr, '&modified',   0)

  call esearch#out#win#modifiable#init()

  if g:esearch_out_win_nvim_lua_syntax
    call luaeval('esearch.appearance.buf_attach_ui()')
  endif

  call esearch#out#win#appearance#annotations#init(esearch)
endfu

fu! esearch#out#win#update#trigger_key_press(...) abort
  call feedkeys("g\<ESC>", 'n')
endfu
