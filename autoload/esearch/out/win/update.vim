fu! esearch#out#win#update#init(esearch) abort
  call extend(a:esearch, {
        \ 'contexts':           [],
        \ 'files_count':        0,
        \ 'separators_count':   0,
        \ 'line_numbers_map':   [],
        \ 'ctx_by_name':        {},
        \ 'ctx_ids_map':        [],
        \ 'render':             function('esearch#out#win#render#'.a:esearch.win_render_strategy.'#do'),
        \})
  aug esearch_win_updates " init blank to prevent errors on cleanup
  aug END
  setl undolevels=-1 noswapfile nonumber norelativenumber nospell nowrap synmaxcol=400
  setl nolist nomodeline foldcolumn=0 buftype=nofile bufhidden=hide foldmethod=marker
  call s:init_header_ctx(a:esearch)

  if a:esearch.request.async
    call s:init_async_updates(a:esearch)
  endif
endfu

fu! s:init_async_updates(esearch) abort
  call extend(a:esearch, {
        \ 'last_update_at':     reltime(),
        \ 'updates_timer':      -1,
        \ 'early_update_limit': a:esearch.batch_size,
        \})

  aug esearch_win_updates
    au! * <buffer>
    exe 'au BufUnload <buffer> call esearch#backend#'.a:esearch.backend."#abort(str2nr(expand('<abuf>')))"
  aug END
  if g:esearch#has#throttle && a:esearch.win_update_throttle_wait > 0
    call s:init_throttled_updates(a:esearch)
  else
    call s:init_instant_updates(a:esearch)
  endif
endfu

fu! s:init_throttled_updates(esearch) abort
  let a:esearch.request.cb.update = function('s:early_update_backend_cb', [bufnr('%')])
  let a:esearch.request.cb.schedule_finish = function('s:early_update_backend_cb', [bufnr('%')])
  let a:esearch.updates_timer = timer_start(
        \ a:esearch.win_update_throttle_wait,
        \ function('s:update_timer_cb', [a:esearch, bufnr('%')]),
        \ {'repeat': -1})
endfu

fu! s:init_header_ctx(esearch) abort
  call esearch#out#win#update#add_context(a:esearch.contexts, '', 1) " add blank header context
  let header_ctx = a:esearch.contexts[0]
  let header_ctx.end = 2
  let a:esearch.ctx_ids_map += [header_ctx.id, header_ctx.id]
  let a:esearch.line_numbers_map += [0, 0]
  setl modifiable
  silent 1,$delete_
  call esearch#util#setline(bufnr('%'), 1, b:esearch.header_text())
  setl nomodifiable
endfu

" rely only on stdout events
fu! s:init_instant_updates(esearch) abort
  let a:esearch.request.cb.update = function('esearch#out#win#update#update', [bufnr('%')])
  let a:esearch.request.cb.schedule_finish = function('esearch#out#win#update#schedule_finish', [bufnr('%')])
endfu

fu! esearch#out#win#update#uninit(esearch) abort
  if has_key(a:esearch, 'updates_timer')
    call timer_stop(a:esearch.updates_timer)
  endif
  exe printf('au! esearch_win_updates * <buffer=%s>', string(a:esearch.bufnr))
endfu

" NOTE is_consumed waits early_finish_wait ms while early_update_backend_cb is
" working.
fu! esearch#out#win#update#can_finish_early(esearch) abort
  if !a:esearch.request.async | return 1 | endif

  let original_early_update_limit = a:esearch.early_update_limit
  let a:esearch.early_update_limit *= 1000
  try
    return a:esearch.request.is_consumed(a:esearch.early_finish_wait)
          \ && (len(a:esearch.request.data) - a:esearch.request.cursor) <= a:esearch.final_batch_size
  finally
    let a:esearch.early_update_limit = original_early_update_limit
  endtry
endfu

fu! s:early_update_backend_cb(bufnr) abort
  if a:bufnr != bufnr('%') | return | endif

  let esearch = getbufvar(a:bufnr, 'esearch')

  if esearch.request.cursor >= esearch.early_update_limit
    let esearch.request.cb.update = 0
    let esearch.request.cb.schedule_finish = 0
    return
  endif

  call esearch#out#win#update#update(a:bufnr)
  if esearch.request.finished && len(esearch.request.data) == esearch.request.cursor
    call esearch#out#win#update#schedule_finish(a:bufnr)
  endif
endfu

fu! s:update_timer_cb(esearch, bufnr, timer) abort
  let elapsed = reltimefloat(reltime(a:esearch.last_update_at)) * 1000
  if elapsed < a:esearch.win_update_throttle_wait | return | endif

  call esearch#out#win#update#update(a:esearch.bufnr)

  let request = a:esearch.request
  if request.finished && len(request.data) == request.cursor
    let a:esearch.updates_timer = -1
    call esearch#out#win#update#schedule_finish(a:esearch.bufnr)
    call timer_stop(a:timer)
  endif
endfu

fu! esearch#out#win#update#add_context(contexts, filename, begin) abort
  call add(a:contexts, {
        \ 'id': len(a:contexts),
        \ 'begin': a:begin,
        \ 'end': 0,
        \ 'filename': a:filename,
        \ 'filetype': '',
        \ 'loaded_syntax': 0,
        \ 'lines': {},
        \ })
endfu

fu! esearch#out#win#update#update(bufnr, ...) abort
  if a:bufnr != bufnr('%') | return | endif

  let esearch = getbufvar(a:bufnr, 'esearch')
  let batched = get(a:, 1, 0)
  let request = esearch.request
  let data = request.data
  let data_size = len(data)

  call setbufvar(a:bufnr, '&modifiable', 1)
  if data_size > request.cursor
    if !batched
          \ || data_size - request.cursor - 1 <= esearch.batch_size
          \ || (request.finished && data_size - request.cursor - 1 <= esearch.final_batch_size)
      let [from, to] = [request.cursor, data_size - 1]
      let request.cursor = data_size
    else
      let [from, to] = [request.cursor, request.cursor + esearch.batch_size - 1]
      let request.cursor += esearch.batch_size
    endif

    call esearch.render(a:bufnr, data, from, to, esearch)
  endif
  call esearch#util#setline(a:bufnr, 1, esearch.header_text())
  call setbufvar(a:bufnr, '&modifiable', 0)

  let esearch.last_update_at = reltime()
endfu

fu! esearch#out#win#update#schedule_finish(bufnr) abort
  if a:bufnr == bufnr('%')
    return esearch#out#win#update#finish(a:bufnr)
  endif

  " Bind event to finish the search as soon as the buffer is entered
  aug esearch_win_updates
    exe printf('au BufEnter <buffer=%d> call esearch#out#win#update#finish(%d)', a:bufnr, a:bufnr)
  aug END
endfu

fu! esearch#out#win#update#finish(bufnr) abort
  if a:bufnr != bufnr('%') | return | endif

  call esearch#util#doautocmd('User esearch_win_finish_pre')
  let esearch = getbufvar(a:bufnr, 'esearch')

  call esearch#out#win#update#update(a:bufnr, 0)
  " TODO
  let esearch.contexts[-1].end = line('$')
  if esearch.win_context_len_annotations
    call luaeval('esearch.appearance.set_context_len_annotation(_A[1], _A[2])',
          \ [esearch.contexts[-1].begin, len(esearch.contexts[-1].lines)])
  endif
  call esearch#out#win#update#uninit(esearch)
  call setbufvar(a:bufnr, '&modifiable', 1)

  if !esearch.current_adapter.is_success(esearch.request)
    call esearch#stderr#finish(esearch)
  endif
  let esearch.header_text = function('esearch#out#win#header#finished_render')
  call esearch#util#setline(a:bufnr, 1, esearch.header_text())

  call setbufvar(a:bufnr, '&modified', 0)
  call esearch#out#win#modifiable#init()

  if esearch.win_ui_nvim_syntax
    call luaeval('esearch.appearance.buf_attach_ui()')
  endif
  call esearch#out#win#appearance#annotations#init(esearch)
  redraw
endfu
