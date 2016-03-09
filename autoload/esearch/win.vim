let s:default_mappings = {
      \ 't':     '<Plug>(esearch-tab)',
      \ 'T':     '<Plug>(esearch-tab-s)',
      \ 'i':     '<Plug>(esearch-split)',
      \ 'I':     '<Plug>(esearch-split-s)',
      \ 's':     '<Plug>(esearch-vsplit)',
      \ 'S':     '<Plug>(esearch-vsplit-s)',
      \ 'R':     '<Plug>(esearch-reload)',
      \ '<Enter>':  '<Plug>(esearch-open)',
      \ 'o':     '<Plug>(esearch-open)',
      \ '<C-n>': '<Plug>(esearch-next)',
      \ '<C-p>': '<Plug>(esearch-prev)',
      \ }
" The first line. It contains information about the number of results
let s:header = '%d matches'
let s:mappings = {}

fu! esearch#win#update() abort
  if esearch#util#cgetfile(b:request)
    return 1
  endif
  setlocal noreadonly
  setlocal modifiable

  call s:extend_results()

  let qf_len = len(b:qf)
  if qf_len > b:_es_iterator
    if qf_len - b:_es_iterator - 1 <= g:esearch.batch_size
      let qfrange = range(b:_es_iterator, qf_len - 1)
      let b:_es_iterator = qf_len
    else
      let qfrange = range(b:_es_iterator, b:_es_iterator + g:esearch.batch_size - 1)
      let b:_es_iterator += g:esearch.batch_size
    endif

    call s:render_results(qfrange)
    call setline(1, printf(s:header, b:_es_iterator))
  endif

  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified
  " exe g:esearch.update_statusline_cmd
  let b:last_update_time = esearch#util#timenow()
endfu

fu! s:extend_results() abort
  if b:handler_running
    if len(b:qf) < len(b:qf_file) - 1 && !empty(b:qf_file)
      call extend(b:qf, esearch#util#parse_results(len(b:qf), len(b:qf_file)-2))
    endif
  else
    if len(b:qf) < len(b:qf_file) && !empty(b:qf_file)
      call extend(b:qf, esearch#util#parse_results(len(b:qf), len(b:qf_file)-1))
    endif
  endif
endfu

fu! s:render_results(qfrange) abort
  let line = line('$') + 1
  for i in a:qfrange
    let fname    = substitute(b:qf[i].fname, b:pwd.'/', '', '')
    let context  = esearch#util#btrunc(b:qf[i].text,
          \ match(b:qf[i].text, b:_es_exp.vim),
          \ g:esearch.context_width.l,
          \ g:esearch.context_width.r)

    if fname !=# b:prev_filename
      let b:_es_columns[fname] = {}
      call setline(line, '')
      let line += 1
      call setline(line, fname)
      let line += 1
    endif
    call setline(line, ' '.printf('%3d', b:qf[i].lnum).' '.context)
    let b:_es_columns[fname][b:qf[i].lnum] = b:qf[i].col
    let line += 1
    let b:prev_filename = fname
  endfor
endfu

fu! esearch#win#init(dir) abort
  augroup EasysearchAutocommands
    au! * <buffer>
    au CursorMoved <buffer> call esearch#handlers#_cursor_moved()
    au CursorHold  <buffer> call esearch#handlers#_cursor_hold()
    au BufLeave    <buffer> let  &updatetime = b:updatetime_backup
    au BufEnter    <buffer> let  b:updatetime_backup = &updatetime |
          \ let &updatetime = float2nr(g:esearch.updatetime)
  augroup END

  call s:init_mappings()

  let b:updatetime_backup = &updatetime
  let &updatetime = float2nr(g:esearch.updatetime)

  let b:qf = []
  let b:pwd = a:dir
  let b:qf_file = []
  let b:qf_entirely_parsed = 0
  let b:_es_iterator    = 0
  let b:handler_running = 0
  let b:prev_filename = ''
  let b:broken_results = []
  let b:_es_columns = {}

  let &iskeyword= g:esearch.wordchars
  setlocal noreadonly
  setlocal modifiable
  exe '1,$d'
  call setline(1, printf(s:header, b:_es_iterator))
  setlocal readonly
  setlocal nomodifiable
  setlocal noswapfile
  setlocal nonumber
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal ft=esearch

  let b:last_update_time = esearch#util#timenow()
endfu


fu! esearch#win#map(map, plug) abort
  " if has_key(s:mappings, a:plug)
    let s:mappings[a:map] = a:plug
  " else
  "   echoerr 'There is no such action: "'.a:plug.'"'
  " endif
endfu

fu! s:init_mappings() abort
  nnoremap <silent><buffer> <Plug>(esearch-tab)       :<C-U>call <sid>open('tabnew')<cr>
  nnoremap <silent><buffer> <Plug>(esearch-tab-s)     :<C-U>call <SID>open('tabnew', 'tabprevious')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-split)     :<C-U>call <SID>open('new')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-split-s)   :<C-U>call <SID>open('new', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-vsplit)    :<C-U>call <SID>open('vnew')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-vsplit-s)  :<C-U>call <SID>open('vnew', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-open)      :<C-U>call <SID>open('edit')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-reload)    :<C-U>call esearch#_start(b:_es_exp, b:pwd)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-prev)      :<C-U>sil exe <SID>jump(0)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-next)      :<C-U>sil exe <SID>jump(1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-Nop) <Nop>

  call extend(s:mappings, s:default_mappings, 'keep')
  for map in keys(s:mappings)
    exe 'nmap <buffer> ' . map . ' ' . s:mappings[map]
  endfor
endfu

fu! s:open(cmd, ...) abort
  let fname = s:filename()
  if !empty(fname)
    let ln = s:line_number()
    let col = get(get(b:_es_columns, fname, {}), ln, 1)
    exe a:cmd . ' ' . fnameescape(b:pwd . '/' . fname)
    call cursor(ln, col)
    norm! zz
    if a:0 | exe a:1 | endif
  endif
endfu

fu! s:jump(downwards) abort
  let pattern = '^\s\+\d\+\s\+.*'
  if a:downwards
    call search(pattern . '\%>4l', 'W')
  else
    call search(pattern, line('.') < 3 ? 'W' : 'Wbe')
  endif

  " return '.|norm! w' " Doesn't works if :set nostartofline, so:
  call search('^', 'Wb', line('.')) " search start of the line
  return 'norm! ww'
endfu

fu! s:filename() abort
  let lnum = search('^\%>2l[^ ]', 'bcWn')
  if lnum == 0
    let lnum = search('^\%>2l[^ ]', 'cWn')
    if lnum == 0 | return '' | endif
  endif

  let filename = matchstr(getline(lnum), '^\zs[^ ].*')
  if empty(filename)
    return ''
  else
    return substitute(filename, '^\./', '', '')
  endif
endfu

fu! s:line_number() abort
  let pattern = '^\%>1l\s\+\d\+.*'

  if line('.') < 3 || match(getline('.'), '^[^ ].*') >= 0
    let lnum = search(pattern, 'cWn')
  else
    let lnum = search(pattern, 'bcWn')
  endif

  return matchstr(getline(lnum), '^\s\+\zs\d\+\ze.*')
endfu
