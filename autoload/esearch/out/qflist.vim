fu! esearch#out#qflist#init(opts) abort
  call setqflist([], '', a:opts.unescaped_title)
  copen

  if a:opts.request.async
    augroup ESearchQFListAutocmds
      au! * <buffer>
      for [func_name, event] in items(a:opts.request.events)
        exe printf('au User %s call esearch#out#qflist#%s(%s)', event, func_name, string(bufnr('%')))
      endfor
      call esearch#backend#{a:opts.backend}#init_events()
    augroup END
  endif
  let b:esearch = extend(a:opts, {
        \ 'ignore_batches':     0,
        \ 'unescaped_title':    ':'.a:opts.unescaped_title,
        \ '__broken_results':    [],
        \ 'errors':              [],
        \ 'data':                [],
        \ 'without':             function('esearch#util#without')
        \})

  call extend(b:esearch.request, {
        \ 'data_ptr':     0,
        \ 'out_finish':   function("esearch#out#qflist#_is_render_finished")
        \})

  au BufReadPost <buffer> let w:quickfix_title = b:esearch.unescaped_title
endfu

fu! esearch#out#qflist#trigger_key_press(...)
  " call feedkeys("\<Plug>(esearch-Nop)")
  call feedkeys("g\<ESC>", 'n')
endfu

fu! esearch#out#qflist#update(bufnr) abort
  let esearch = getbufvar(a:bufnr, 'esearch')
  let ignore_batches = esearch.ignore_batches
  let request = esearch.request

  let data = esearch.request.data
  let data_size = len(data)
  if data_size > request.data_ptr
    if ignore_batches || data_size - request.data_ptr - 1 <= esearch.batch_size
      let [from,to] = [request.data_ptr, data_size - 1]
      let request.data_ptr = data_size
    else
      let [from, to] = [request.data_ptr, request.data_ptr + esearch.batch_size - 1]
      let request.data_ptr += esearch.batch_size
    endif

    let parsed = esearch#adapter#{esearch.adapter}#parse_results(
          \ data, from, to, esearch.__broken_results, esearch.exp.vim)


    for p in parsed
      let p.filename = fnamemodify(p.filename, ':~:.')
    endfor

    if a:bufnr == bufnr('%')
      let curpos = getcurpos()[1:]
      call setqflist(parsed, 'a')
      call cursor(curpos)
    else
      noau call setqflist(parsed, 'a')
    endif
  endif
endfu

fu! esearch#out#qflist#forced_finish(bufnr)
  call esearch#out#qflist#finish(a:bufnr)
endfu

fu! esearch#out#qflist#finish(bufnr)

  let esearch = getbufvar(a:bufnr, 'esearch')

  if esearch.request.async
    au! ESearchQFListAutocmds * <buffer>
    for [func_name, event] in items(esearch.request.events)
      exe printf('au! ESearchQFListAutocmds User %s ', event)
    endfor
  endif

  " Update using all remaining request.data
  let esearch.ignore_batches = 1
  call esearch#out#qflist#update(a:bufnr)

  let esearch.unescaped_title = esearch.unescaped_title . '. Finished.'

  for tabnr in range(1, tabpagenr('$'))
    let buflist = tabpagebuflist(tabnr)
    if index(buflist, a:bufnr) >= 0
      for winnr in range(1, tabpagewinnr(tabnr, '$'))
        if buflist[winnr - 1] == a:bufnr
          call settabwinvar(tabnr, winnr, 'quickfix_title', esearch.unescaped_title)
        endif
      endfor
    endif
  endfor

  do User ESearchOutputFinishQFList
endfu

" For some reasons s:_is_render_finished fails in Travis
fu! esearch#out#qflist#_is_render_finished() dict abort
  return self.data_ptr == len(self.data)
endfu

