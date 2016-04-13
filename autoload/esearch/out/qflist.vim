fu! esearch#out#qflist#init(opts) abort
  call setqflist([], '', a:opts.unescaped_title)
  copen

  if a:opts.request.async
    call esearch#out#qflist#setup_autocmds(a:opts)
  endif
  let g:esearch_qf = extend(a:opts, {
        \ 'ignore_batches':     0,
        \ 'unescaped_title':    ':'.a:opts.unescaped_title,
        \ '__broken_results':    [],
        \ 'errors':              [],
        \ 'data':                [],
        \ 'without':             function('esearch#util#without')
        \})


  call extend(g:esearch_qf.request, {
        \ 'data_ptr':     0,
        \ 'out_finish':   function('esearch#out#qflist#_is_render_finished')
        \})
endfu

fu! esearch#out#qflist#setup_autocmds(opts)
  augroup ESearchQFListAutocmds
    au! * <buffer>
    for [func_name, event] in items(a:opts.request.events)
      exe printf('au User %s call esearch#out#qflist#%s()', event, func_name)
    endfor
    call esearch#backend#{a:opts.backend}#init_events()

    " Keep only User cmds(reponsible for results updating) and qf initialization
    au BufUnload <buffer> exe "au! ESearchQFListAutocmds * <abuf> "

    " We need to handle quickfix bufhidden=wipe behaviour
    if !exists('#ESearchQFListAutocmds#FileType')
      au FileType qf
            \ if exists('g:esearch_qf') && !g:esearch_qf.request.finished && esearch#util#qftype(bufnr('%')) ==# 'qf' |
            \   call esearch#out#qflist#setup_autocmds(g:esearch_qf) |
            \ endif
      " TODO improve
      au FileType qf
            \ if exists('w:quickfix_title') && exists('g:esearch_qf') && g:esearch_qf.unescaped_title =~# w:quickfix_title |
            \   let w:quickfix_title = g:esearch_qf.unescaped_title |
            \ endif
    endif
  augroup END
endfu

fu! esearch#out#qflist#trigger_key_press(...) abort
  " call feedkeys("\<Plug>(esearch-Nop)")
  call feedkeys("g\<ESC>", 'n')
endfu

fu! esearch#out#qflist#update() abort
  let esearch = g:esearch_qf
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

    if esearch#util#qftype(bufnr('%')) ==# 'qf'
      let curpos = getcurpos()[1:]
      noau call setqflist(parsed, 'a')
      call cursor(curpos)
    else
      noau call setqflist(parsed, 'a')
    endif
  endif
endfu

fu! esearch#out#qflist#forced_finish() abort
  call esearch#out#qflist#finish()
endfu

fu! esearch#out#qflist#finish() abort
  let esearch = g:esearch_qf

  if esearch.request.async
    au! ESearchQFListAutocmds * <buffer>
    for [func_name, event] in items(esearch.request.events)
      exe printf('au! ESearchQFListAutocmds User %s ', event)
    endfor
  endif

  " Update using all remaining request.data
  let esearch.ignore_batches = 1
  call esearch#out#qflist#update()

  let esearch.unescaped_title = esearch.unescaped_title . '. Finished.'

  if esearch#util#qftype(bufnr('%')) ==# 'qf'
    let w:quickfix_title = esearch.unescaped_title
  else
    let bufnr = esearch#util#qfbufnr()
    if bufnr !=# -1
      for tabnr in range(1, tabpagenr('$'))
        let buflist = tabpagebuflist(tabnr)
        if index(buflist, bufnr) >= 0
          for winnr in range(1, tabpagewinnr(tabnr, '$'))
            if buflist[winnr - 1] == bufnr
              call settabwinvar(tabnr, winnr, 'quickfix_title', esearch.unescaped_title)
            endif
          endfor
        endif
      endfor
    endif

  endif

  do User ESearchOutputFinishQFList
endfu

" For some reasons s:_is_render_finished fails in Travis
fu! esearch#out#qflist#_is_render_finished() dict abort
  return self.data_ptr == len(self.data)
endfu

