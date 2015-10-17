let s:easysearch_batch_size = 1500
let s:default_mappings = {
      \ '<Plug>(easysearch-T)': 'T',
      \ '<Plug>(easysearch-t)': 't',
      \ '<Plug>(easysearch-s)': 's',
      \ '<Plug>(easysearch-S)': 'S',
      \ '<Plug>(easysearch-v)': 'v',
      \ '<Plug>(easysearch-V)': 'V',
      \ '<Plug>(easysearch-cr)': '<CR>',
      \ '<Plug>(easysearch-cp)': '<C-p>',
      \ '<Plug>(easysearch-cn)': '<C-n>',
      \ }

let s:mappings = {}

fu! easysearch#win#init()
  setlocal noreadonly
  setlocal modifiable
  exe '1,$d'
  setlocal readonly
  setlocal nomodifiable
  setlocal noswapfile
  setlocal nonumber
  setlocal buftype=nofile
  setlocal ft=esearch

  let b:updatetime_backup = &updatetime
  let &updatetime = float2nr(g:esearch_settings.updatetime)

  let b:qf = []
  let b:pwd = $PWD
  let b:qf_file = []
  let b:qf_entirely_parsed = 0
  let b:last_index    = 0

  augroup EasysearchAutocommands
    au!
    au CursorMoved <buffer> call easysearch#handlers#cursor_moved()
    au CursorHold  <buffer> call easysearch#handlers#cursor_hold()
    au BufLeave    <buffer> let  &updatetime = b:updatetime_backup
    au BufEnter    <buffer> let  b:updatetime_backup = &updatetime
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

fu! easysearch#win#update()
  if easysearch#util#cgetfile(b:request)
    return 1
  endif
  setlocal noreadonly
  setlocal modifiable
  " if b:last_index == len(b:qf) && len(b:qf_file) != 0
  if len(b:qf) < len(b:qf_file) && !empty(b:qf_file)
    call extend(b:qf, easysearch#util#parse_results(b:last_index, len(b:qf_file)), 'keep')
  endif

  call setline(1, len(b:qf) . ' matches')
  call setline(2, '')

  let qf_len = len(b:qf)
  if qf_len > b:last_index
    if qf_len - b:last_index  < s:easysearch_batch_size
      let qfrange = range(b:last_index, qf_len - 1)
      let b:last_index = qf_len
      " let b:qf_entirely_parsed = 1
    else
      let qfrange = range(b:last_index, b:last_index + s:easysearch_batch_size - 1)
      let b:last_index += s:easysearch_batch_size
      let b:qf_entirely_parsed = 0
    endif

    call s:render_results(qfrange)
  endif

  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified
  call s:update_statusline()
  let b:last_update_time = easysearch#util#timenow()
endfu

fu! s:render_results(qfrange)
  let line = line('$')
  let prev_filename = ''
  for i in a:qfrange
    let match_text  = b:qf[i].text
    let fname    = substitute(b:qf[i].fname, b:pwd.'/', '', '')

    if fname !=# prev_filename
      call setline(line, '')
      let line += 1
      call setline(line, fname)
      let line += 1
    endif
    call setline(line, ' '.printf('%3d', b:qf[i].lnum).' '.easysearch#util#trunc_str(match_text, 80))
    let line += 1
    let prev_filename = fname
  endfor
endfu

fu! s:init_mappings()
  nnoremap <silent><buffer> <Plug>(easysearch-t)   :call <sid>open('tabnew')<cr>
  nnoremap <silent><buffer> <Plug>(easysearch-T)   :call <SID>open('tabnew', 'tabprevious')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-s)   :call <SID>open('new')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-S)   :call <SID>open('new', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-v)   :call <SID>open('vnew')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-V)   :call <SID>open('vnew', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cr)  :call <SID>open('edit')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cn)  :<C-U>sil exe <SID>move(1)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cp)  :<C-U>sil exe <SID>move(-1)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-Nop) <Nop>

  call extend(s:mappings, s:default_mappings, 'keep')
  for plug in keys(s:mappings)
    exe 'nmap <buffer> ' . s:mappings[plug] . ' ' . plug
  endfor
endfu

fu! s:open(cmd, ...)
  let new_cursor_pos = [s:line_number(), 1]
  let fname = s:filename()
  if !empty(fname)
    exe a:cmd . ' ' . fname
    call cursor(new_cursor_pos)
    norm! zz
    if a:0 | exe a:1 | endif
  endif
endfu

fu! s:move(direction)
  let pattern = '^\s\+\d\+\s\+.*'
  if a:direction == 1
    call search(pattern, 'W')
  else
    call search(pattern, 'Wbe')
  endif

  return '.|norm! w'
endfu

fu! s:filename()
  let lnum = search('^\%>1l[^ ]', 'bcWn')
  if lnum == 0
    let lnum = search('^\%>1l[^ ]', 'cWn')
    if lnum == 0 | return '' | endif
  endif

  let filename = matchstr(getline(lnum), '^\zs[^ ].\+')
  if empty(filename)
    return ''
  else
    return b:pwd . '/' . filename
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

