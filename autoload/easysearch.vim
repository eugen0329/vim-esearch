let s:easysearch_batch_size = 1500
let s:updatetime = 300.0
let s:header_height = 3
let s:elem_height = 3


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

let s:custom_mappings = {}

fu! easysearch#init_mappings()
  nnoremap <silent><buffer> <Plug>(easysearch-t)   :call <sid>open('tabnew', 0)<cr>
  nnoremap <silent><buffer> <Plug>(easysearch-T)   :call <SID>open('tabnew', 1, 'tabprevious')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-s)   :call <SID>open('new', 0)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-S)   :call <SID>open('new', 1, 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-v)   :call <SID>open('vnew',  0)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-V)   :call <SID>open('new', 1, 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cr)  :call <SID>open('tabnew', 0)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cn)  :call <SID>move(1)<CR>
  nnoremap <silent><buffer> <Plug>(easysearch-cp)  :call <SID>move(-1)<CR>
  nnoremap <silent><buffer> [_esrch] <Nop>

  for plug in keys(s:custom_mappings)
    exe 'nmap <buffer> ' . s:custom_mappings[plug] . ' ' . plug
  endfor

  for plug in keys(s:default_mappings)
    if !hasmapto(plug)
      exe 'map <buffer> ' . s:default_mappings[plug] . ' ' . plug
    endif
  endfor
endfu

fu! easysearch#map(map, plug)
  if a:plug == '<Plug>(easysearch)'
    exe 'map ' . a:map . ' ' . a:plug
  else
    let s:custom_mappings[a:plug] = a:map
  endif
endfu

fu! s:move(direction)
  if a:direction == 1
    call search('^\s\{2}\d\+.*', 'W')
  else
    call search('^\s\{2}\d\+.*', 'Wb')
  endif
endfu

fu! s:filename()
  let lnum = search('^\%>1l[^ ]', 'bcWn')
  if lnum == 0
    let lnum = search('^\%>1l[^ ]', 'cWn')
  endif

  return matchstr(getline(lnum), '^\zs[^ ].\+')
endfu

fu! s:line_number()
  let lnum = search('^\%>1l\s\{2}\d\+.*', 'bcWn')
  if lnum == 0
    let lnum = search('^\%>1l\s\{2}\d\+.*', 'cWn')
  endif

  return matchstr(getline(lnum), '^\s\{2}\zs\d\+\ze.*')
endfu

fu! s:open(cmd, silent, ...)
  " let cursorpos = getpos('.')
  " let ln = (cursorpos[1] - s:header_height) / s:elem_height

  " if ln < len(b:qf)
    " let new_cursor_pos = [str2nr(b:qf[ln].lnum), str2nr(b:qf[ln].col)]
    let new_cursor_pos = [s:line_number(), 1]
    " let bufnr = get(b:qf[ln], 'bufnr', '')
    " if empty(bufnr)
      let fname = s:filename()
      exe a:cmd . '|e ' . fname
    " else
    "   exe a:cmd . '|b ' . b:qf[ln].bufnr
    " endif
    call cursor(new_cursor_pos)

    if a:silent | exe a:1 | endif
  " endif
endfu
