if exists('g:loaded_easy_search')
  finish
endif
let g:loaded_easy_search = 1

let s:easysearch_batch_size = 1500
let s:updatetime = 300.0
let s:header_height = 3
let s:elem_height = 3

noremap <silent><Plug>(easysearch) :<C-u>call <SID>easy_search(0)<CR>
xnoremap <silent><Plug>(easysearch) :<C-u>call <SID>easy_search(1)<CR>

if !hasmapto('<Plug>(easymotion-prefix)')
  map <leader>ff <Plug>(easysearch)
endif

fu! s:easy_search(visual)
  if a:visual
    let initial_search_val = s:get_visual_selection()
  else
    let initial_search_val = ''
  endif

  let search_str = s:escape_search_string(input('pattern >>> ', initial_search_val))
  if search_str == ''
    return ''
  endif
  call s:init_results_buffer(search_str)
endfu

fu! s:init_results_buffer(search_str)
  let results_bufname = "Search:\ '" . substitute(a:search_str, ' ', '\ ', 'g') . "'"

  let results_bufnr = bufnr('^'.results_bufname.'$')
  if results_bufnr > 0
    let buf_loc = s:find_buf_loc(results_bufnr)
    if buf_loc != []
      exe 'tabn ' . buf_loc[0]
      exe buf_loc[1].'winc w'
    else
      exe 'tabnew|b ' . results_bufnr
    endif
  else
    exe 'tabnew'
    let results_bufnr = bufnr('%')
    exe 'file "'.results_bufname.'"'
  endif

  let b:qf = []
  let b:qf_file = []
  call setqflist([])
  let b:qf_entirely_parsed = 0
  let b:last_index    = 0
  let s:updatetime_bak = &updatetime

  if line('$') > s:header_height
    setlocal noreadonly
    setlocal modifiable
    exe s:header_height.',$d'
  endif

  augroup EasysearchAutocommands
    au!
    au CursorMoved <buffer> call s:on_cursor_moved()
    au CursorHold  <buffer> call s:on_cursor_hold()
  augroup END

  setlocal readonly
  setlocal nomodifiable
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal ft=esearch
  setlocal nonumber
  let &updatetime = float2nr(s:updatetime)

  call easysearch#init_mappings()

  exe 'Dispatch! ag -Q --nogroup --nocolor --column "' . a:search_str  . '"'
  let b:request = dispatch#request()
  let b:request.format = '%f:%l:%c:%m,%f:%l:%m'
  let b:request.background = 1

  call s:cgetfile(b:request)
  call s:update_results(0)
endfu

fu! s:on_cursor_hold()
  let qf_entirely_parsed = len(b:qf_file) == b:last_index && b:qf_entirely_parsed
  if !s:running(b:request.handler, b:request.pid) && qf_entirely_parsed
    exe 'au! EasysearchAutocommands'
    let &updatetime = float2nr(s:updatetime_bak)
    let b:request.background = 0

    call s:update_results(1)
    call s:update_statusline()
  else
    call s:cgetfile(b:request)
    call s:update_results(0)
    call s:update_statusline()
    call feedkeys('[_esrch]')
  endif
endfu

fu! s:on_cursor_moved()
  if  s:timenow() < &updatetime/1000.0 + s:last_update_time
    return -1
  endif

  let qf_entirely_parsed = len(b:qf_file) == b:last_index && b:qf_entirely_parsed
  if !s:running(b:request.handler, b:request.pid) && qf_entirely_parsed
    exe 'au! EasysearchAutocommands'
    let &updatetime = float2nr(s:updatetime_bak)

    call s:cgetfile(b:request)
    call s:update_results(1)
    call s:update_statusline()
  else
    call s:cgetfile(b:request)
    call s:update_results(0)
    call s:update_statusline()
  endif
endfu

fu! s:trunc_str(str, size)
  if len(a:str) > a:size
    return a:str[:a:size] . '…'
  endif

  return a:str
endfu

fu! s:update_results(...)
  setlocal noreadonly
  setlocal modifiable

  if b:last_index == len(b:qf) && len(b:qf_file) != 0
    call extend(b:qf, s:parse_qf(b:last_index, len(b:qf_file)))
  endif
  let results_count = len(b:qf)

  call setline(1, results_count . ' matches' . (len(a:000) > 0 && a:1 == 1 ? '. Finished.' : ''))
  call setline(2, '')

  let qf_len = len(b:qf)
  if qf_len > b:last_index
    if s:running(b:request.handler, b:request.pid) || qf_len - b:last_index + 1 <= s:easysearch_batch_size
      let qfrange = range(b:last_index, qf_len - 1)
      let b:last_index = qf_len
      let b:qf_entirely_parsed = 1
    else
      let qfrange = range(b:last_index, b:last_index + s:easysearch_batch_size - 1)
      let b:last_index += s:easysearch_batch_size
      let b:qf_entirely_parsed = 0
    endif

    let line = line('$')
    let prev_filename = -1
    for i in l:qfrange
      let match_text  = b:qf[i].text
      let filename    = b:qf[i].fname

      if filename != prev_filename
        call setline(line, '')
        let line += 1
        call setline(line,  i+1.'. '.filename)
        let line += 1
      endif
      call setline(line, '  ' . b:qf[i].lnum . ' ' . s:trunc_str(match_text, 80))
      let line += 1
      let prev_filename = filename
    endfor
  endif

  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified
  let s:last_update_time = s:timenow()
endfu

fu! s:update_statusline()
  if exists('*lightline#update_once')
    call lightline#update_once()
  elseif exists('AirlineRefresh')
    AirlineRefresh
  endif
endfu

fu! s:escape_search_string(str)
  return substitute(a:str, '["#$%]', '\\\0', 'g')
endfu


fu! s:open_in_split(cmd, silent)
  let cursorpos = getpos('.')
  let ln = (cursorpos[1] - s:header_height) / s:elem_height

  if ln < len(b:qf)
    let new_cursor_pos = [b:qf[ln].lnum, b:qf[ln].col]
    exe a:cmd . '|b ' . b:qf[ln].bufnr
    call cursor(new_cursor_pos)
    if a:silent
      exe 'silent wincmd p'
    endif
  endif
endfu

fu! s:timenow()
  let now = reltime()
  return str2float(reltimestr([now[0] % 10000, now[1]/1000 * 1000]))
endfu

" Extracted from tpope/dispatch
fu! s:request_status()
  let request = b:request
  try
    let status = str2nr(readfile(request.file . '.complete', 1)[0])
  catch
    let status = -1
  endtry
  return status
endfu

function! s:cgetfile(request) abort
  let request = a:request
  let efm = &l:efm
  let makeprg = &l:makeprg
  let compiler = get(b:, 'current_compiler', '')
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  let dir = getcwd()
  let modelines = &modelines
  try
    let &modelines = 0
    exe cd fnameescape(request.directory)
    let b:qf_file = readfile(fnameescape(request.file))
  catch '^E40:'
    echohl Error | echo v:exception | echohl None
  finally
    let &modelines = modelines
    exe cd fnameescape(dir)
  endtry
endfunction

fu! s:parse_qf(from, to)
  if b:qf_file == [] | return [] | endif
  let r = '^\(.\{-}\)\:\(\d\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'
  let results = []

  for i in range(a:from, a:to - 1)
    let el = matchlist(b:qf_file[i], r)[1:4]
    if empty(el) | continue | endif
    let new_result_elem = { 'fname': el[0], 'lnum': el[1], 'col': el[2], 'text': el[3] }
    call add(results, new_result_elem)
  endfor
  return results
endfu

fu! s:find_buf_loc(bufnr)
  for tabnr in range(1, tabpagenr('$'))
    if tabpagenr() == tabnr | continue | endif

    let buflist = tabpagebuflist(tabnr)
    if index(buflist, a:bufnr) >= 0
      for winnr in range(1, tabpagewinnr(tabnr, '$'))
        if buflist[winnr - 1] == a:bufnr | return [tabnr, winnr] | endif
      endfor
    endif
  endfor

  return []
endf

function! s:running(handler, pid) abort
  if empty(a:pid)
    return 0
  elseif exists('*dispatch#'.a:handler.'#running')
    return dispatch#{a:handler}#running(a:pid)
  elseif has('win32')
    let tasklist_cmd = 'tasklist /fi "pid eq '.a:pid.'"'
    if &shellxquote ==# '"'
      let tasklist_cmd = substitute(tasklist_cmd, '"', "'", "g")
    endif
    return system(tasklist_cmd) =~# '==='
  else
    call system('kill -0 '.a:pid)
    return !v:shell_error
  endif
endfunction

function! s:get_visual_selection()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction

