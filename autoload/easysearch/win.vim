let s:easysearch_batch_size = 1500
let s:updatetime = 300.0
let s:default_mappings = {
      \ '<Plug>(easysearch-T)': 'T',
      \ '<Plug>(easysearch-t)': 't',
      \ '<Plug>(easysearch-s)': 's',
      \ '<Plug>(easysearch-v)': 'v',
      \ '<Plug>(easysearch-S)': 'S',
      \ '<Plug>(easysearch-cp)': '<C-p>',
      \ '<Plug>(easysearch-cn)': '<C-n>',
      \ '<Plug>(easysearch-cr)': '<CR>',
      \ }

let s:mappings = {}

fu! easysearch#win#init()
  setlocal readonly
  setlocal nomodifiable
  setlocal noswapfile
  setlocal nonumber
  setlocal buftype=nofile
  setlocal ft=esearch
  let &updatetime = float2nr(s:updatetime)

  let b:qf = []
  let b:qf_file = []
  let b:qf_entirely_parsed = 0
  let b:last_index    = 0
  " let s:updatetime_bak = &updatetime

  augroup EasysearchAutocommands
    au!
    au CursorMoved <buffer> call easysearch#handlers#cursor_moved()
    au CursorHold  <buffer> call easysearch#handlers#cursor_hold()
  augroup END

  call s:init_mappings()
endfu

fu! easysearch#win#map(map, plug)
  if has_key(s:mappings, a:plug)
    let s:mappings[a:plug] = a:map
  else
    echoerr 'There is no such action: "'.a:plug.'"'
  endif
endfu

fu! easysearch#win#update(...)
  setlocal noreadonly
  setlocal modifiable

  if b:last_index == len(b:qf) && len(b:qf_file) != 0
    call extend(b:qf, easysearch#util#parse_results(b:last_index, len(b:qf_file)))
  endif
  let results_count = len(b:qf)

  call setline(1, results_count . ' matches' . (len(a:000) > 0 && a:1 == 1 ? '. Finished.' : ''))
  call setline(2, '')

  let qf_len = len(b:qf)
  if qf_len > b:last_index
    if easysearch#util#running(b:request.handler, b:request.pid) || qf_len - b:last_index + 1 <= s:easysearch_batch_size
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
        call setline(line, filename)
        let line += 1
      endif
      call setline(line, '  '.printf('%3d', b:qf[i].lnum).' '.easysearch#util#trunc_str(match_text, 80))
      let line += 1
      let prev_filename = filename
    endfor
  endif

  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified
  call s:update_statusline()
  let b:last_update_time = easysearch#util#timenow()
endfu

fu! s:init_mappings()
  nnoremap <silent><buffer> <Plug>(easysearch-t)   :call <sid>open('tabnew', 0)<cr>
  nnoremap <silent><buffer> <Plug>(easysearch-T)   :call <SID>open('tabnew', 1, 'tabprevious')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-s)   :call <SID>open('new', 0)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-S)   :call <SID>open('new', 1, 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-v)   :call <SID>open('vnew',  0)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-V)   :call <SID>open('new', 1, 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cr)  :call <SID>open('tabnew', 0)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cn)  :<C-U>exe <SID>move(1)<Bar>norm! w<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cp)  :<C-U>exe <SID>move(-1)<Bar>norm! w<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-Nop) <Nop>

  call extend(s:mappings, s:default_mappings, 'keep')
  for plug in keys(s:mappings)
    exe 'nmap <buffer> ' . s:mappings[plug] . ' ' . plug
  endfor
endfu

fu! s:open(cmd, silent, ...)
  let new_cursor_pos = [s:line_number(), 1]
  let fname = s:filename()
  if !empty(fname)
    exe a:cmd . '|e ' . fname
    call cursor(new_cursor_pos)
    norm! zz
    if a:silent | exe a:1 | endif
  endif
endfu

fu! s:move(direction)
  let pattern = '^\s\+\d\+\s\+\zs.*'
  if a:direction == 1
    call search(pattern, 'W')
  else
    call search(pattern, 'Wbe')
  endif

  return '.'
endfu

fu! s:filename()
  let lnum = search('^\%>1l[^ ]', 'bcWn')
  if lnum == 0
    let lnum = search('^\%>1l[^ ]', 'cWn')
  endif

  if lnum == 0
    return ''
  else
  return matchstr(getline(lnum), '^\zs[^ ].\+')
  endif
endfu

fu! s:line_number()
  let pattern = '^\%>1l\s\+\d\+.*'

  if line('.') < 3 || match(getline('.'), '^[^ ].*') >= 0
    let lnum = search(pattern, 'cWn')
  else
    let lnum = search(pattern, 'bcWn')
  endif

  return matchstr(getline(lnum), '^\s\+\zs\d\+\ze.*')
endfu

fu! s:update_statusline()
  if exists('*lightline#update_once')
    call lightline#update_once()
  elseif exists('AirlineRefresh')
    AirlineRefresh
  endif
endfu

