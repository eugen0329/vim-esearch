fu! esearch#out#qflist#init(esearch) abort
  if has_key(g:, 'esearch_qf')
    call esearch#backend#{g:esearch_qf.backend}#abort(bufnr('%'))
  end
  call setqflist([])
  copen
  if a:esearch.request.async
    call esearch#out#qflist#setup_autocmds(a:esearch)
  endif
  let g:esearch_qf = extend(a:esearch, {'title': ':'.a:esearch.title})
  let w:quickfix_title = g:esearch_qf.title
  if !g:esearch_qf.request.async
    call esearch#out#qflist#finish()
  endif
endfu

fu! esearch#out#qflist#setup_autocmds(esearch) abort
  aug ESearchQFListAutocmds
    au! * <buffer>
    let a:esearch.request.cb.update = function('esearch#out#qflist#update')
    let a:esearch.request.cb.schedule_finish = function('esearch#out#qflist#schedule_finish')

    " Keep only User cmds(reponsible for results updating) and qf initialization
    au BufUnload <buffer> exe "au! ESearchQFListAutocmds * <abuf> "
    exe 'au BufUnload <buffer> call esearch#backend#'.a:esearch.backend."#abort(str2nr(expand('<abuf>')))"

    " We need to handle quickfix bufhidden=wipe behavior
    if !exists('#ESearchQFListAutocmds#FileType')
      au FileType qf
            \ if exists('g:esearch_qf') && !g:esearch_qf.request.finished && esearch#buf#qftype(bufnr('%')) ==# 'qf' |
            \   call esearch#out#qflist#setup_autocmds(g:esearch_qf) |
            \ endif
    endif
  aug END
endfu

fu! esearch#out#qflist#update(...) abort
  let esearch = g:esearch_qf
  let batched = get(a:, 1, 0)

  let request = esearch.request
  let data = esearch.request.data
  let data_size = len(data)
  if data_size > request.cursor
    if batched || data_size - request.cursor - 1 <= esearch.batch_size
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
  call esearch#out#qflist#update(0)

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
endfu
