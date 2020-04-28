fu! esearch#out#qflist#init(opts) abort
  if has_key(g:, 'esearch_qf')
    call esearch#backend#{g:esearch_qf.backend}#abort(bufnr('%'))
  end

  call setqflist([])
  copen

  if a:opts.request.async
    call esearch#out#qflist#setup_autocmds(a:opts)
  endif
  aug ESearchQFListNameHack
    " TODO improve
    au!
    au FileType qf
          \ if exists('w:quickfix_title') && exists('g:esearch_qf') && g:esearch_qf.title =~# w:quickfix_title |
          \   let w:quickfix_title = g:esearch_qf.title |
          \ endif
  aug END

  call s:init_commands()

  let g:esearch_qf = extend(a:opts, {
        \ 'ignore_batches':   0,
        \ 'title':            ':'.a:opts.title,
        \})

  if g:esearch_qf.request.async
    let w:quickfix_title = g:esearch_qf.title
  else
    call esearch#out#qflist#finish()
  endif
endfu

fu! esearch#out#qflist#setup_autocmds(opts) abort
  aug ESearchQFListAutocmds
    au! * <buffer>
    for [func_name, Event] in items(a:opts.request.events)
      let a:opts.request.events[func_name] = function('esearch#out#qflist#' . func_name)
    endfor
    call esearch#backend#{a:opts.backend}#init_events()

    " Keep only User cmds(reponsible for results updating) and qf initialization
    au BufUnload <buffer> exe "au! ESearchQFListAutocmds * <abuf> "

    " We need to handle quickfix bufhidden=wipe behavior
    if !exists('#ESearchQFListAutocmds#FileType')
      au FileType qf
            \ if exists('g:esearch_qf') && !g:esearch_qf.request.finished && esearch#buf#qftype(bufnr('%')) ==# 'qf' |
            \   call esearch#out#qflist#setup_autocmds(g:esearch_qf) |
            \ endif
    endif
  aug END
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
  if data_size > request.cursor
    if ignore_batches || data_size - request.cursor - 1 <= esearch.batch_size
      let [from,to] = [request.cursor, data_size - 1]
      let request.cursor = data_size
    else
      let [from, to] = [request.cursor, request.cursor + esearch.batch_size - 1]
      let request.cursor += esearch.batch_size
    endif

    let cwd = esearch#win#lcd(esearch.cwd)
    try
      let [parsed, _separators_count] = esearch.parse(data, from, to)
      if esearch#buf#qftype(bufnr('%')) ==# 'qf'
        let curpos = getcurpos()[1:]
        noau call setqflist(parsed, 'a')
        call cursor(curpos)
      else
        noau call setqflist(parsed, 'a')
      endif
    finally
      call cwd.restore()
    endtry
  endif
endfu

fu! esearch#out#qflist#schedule_finish() abort
  call esearch#out#qflist#finish()
endfu

fu! esearch#out#qflist#finish() abort
  let esearch = g:esearch_qf

  if esearch.request.async
    au! ESearchQFListAutocmds * <buffer>
  endif

  " Update using all remaining request.data
  let esearch.ignore_batches = 1
  call esearch#out#qflist#update()

  let esearch.title = esearch.title . '. Finished.'

  if esearch#buf#qftype(bufnr('%')) ==# 'qf'
    let w:quickfix_title = esearch.title
  else
    let bufnr = esearch#buf#qfbufnr()
    if bufnr !=# -1
      for tabnr in range(1, tabpagenr('$'))
        let buflist = tabpagebuflist(tabnr)
        if index(buflist, bufnr) >= 0
          for winnr in range(1, tabpagewinnr(tabnr, '$'))
            if buflist[winnr - 1] == bufnr
              call settabwinvar(tabnr, winnr, 'quickfix_title', esearch.title)
            endif
          endfor
        endif
      endfor
    endif

  endif

  silent doau User ESearchOutputFinishQFList
endfu

fu! s:init_commands() abort
  let s:win = {
        \ 'line_in_file': function('s:line_in_file'),
        \ 'open':         function('s:open'),
        \ 'filename':     function('s:filename'),
        \ 'is_entry':     function('s:is_entry')
        \}
  command! -nargs=1 -range=0 -bar -buffer  -complete=custom,esearch#substitute#complete ESubstitute
        \ call esearch#substitute#do(<q-args>, <line1>, <line2>, s:win)

  if exists(':E') != 2
    command! -nargs=1 -range=0 -bar -buffer -complete=custom,esearch#substitute#complete E
          \ call esearch#substitute#do(<q-args>, <line1>, <line2>, s:win)
  elseif exists(':ES') != 2
    command! -nargs=1 -range=0 -bar -buffer  -complete=custom,esearch#substitute#complete ES
          \ call esearch#substitute#do(<q-args>, <line1>, <line2>, s:win)
  endif
endfu

" Required for ESubstitute
fu! s:line_in_file() abort
  let qf = getqflist()
  let qfln = line('.')

  return qf[qfln-1].lnum
endfu

fu! s:open(cmd, ...) abort
  let fname = s:filename()
  if !empty(fname)
    let qf = getqflist()
    let qfln = line('.')
    let ln = qf[qfln-1].lnum
    let col = qf[qfln-1].col

    let cmd = (a:0 ? 'noautocmd ' :'') . a:cmd

    try
      " See #win NOTE 1
      unsilent exe a:cmd . ' ' . fnameescape(g:esearch_qf.cwd . '/' . fname)
    catch /E325:/
      " ignore warnings about swapfiles (let user and #substitute handle them)
    catch
      unsilent echo v:exception . ' at ' . v:throwpoint
    endtry

    keepjumps call cursor(ln, col)
    norm! zz
    if a:0 | exe a:1 | endif
  endif
endfu

fu! s:filename() abort
  let qf = getqflist()
  let qfln = line('.')

  return bufname(qf[qfln-1].bufnr)
endfu

fu! s:is_entry() abort
  return 1 " always true
endfu
