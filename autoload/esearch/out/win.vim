" NOTE 1 (unsilent when opening files)
" We expect to receive the following if use #substitute#do over files with an
" existing swap:
" |0 files changed
" |The following files has unresolved swapfiles
" |    file_with_existed_swap.foo
" But instead:
" |0 files changed
" |The following files has unresolved swapfiles
" |"Search: `query`" [readonly] line 5 of 25 --20%-- col 12
"
" Have no idea why it's so (and time to deal) ...

let s:default_mappings = {
      \ 't':       '<Plug>(esearch-tab)',
      \ 'T':       '<Plug>(esearch-tab-silent)',
      \ 'i':       '<Plug>(esearch-split)',
      \ 'I':       '<Plug>(esearch-split-silent)',
      \ 's':       '<Plug>(esearch-vsplit)',
      \ 'S':       '<Plug>(esearch-vsplit-silent)',
      \ 'R':       '<Plug>(esearch-reload)',
      \ '<Enter>': '<Plug>(esearch-open)',
      \ 'o':       '<Plug>(esearch-open)',
      \ '<C-n>':   '<Plug>(esearch-next)',
      \ '<C-p>':   '<Plug>(esearch-prev)',
      \ '<S-j>':   '<Plug>(esearch-next-file)',
      \ '<S-k>':   '<Plug>(esearch-prev-file)',
      \ }

" The first line. It contains information about the number of results
let s:header = 'Matches in %d lines'
let s:mappings = {}
let s:file_entry_pattern = '^\s\+\d\+\s\+.*'
let s:filename_pattern = '^[^ ]' " '\%>2l'

if !has_key(g:, 'esearch#out#win#open')
  let g:esearch#out#win#open = 'tabnew'
endif


" TODO wrap arguments with hash
fu! esearch#out#win#init(opts) abort
  call s:find_or_create_buf(a:opts.bufname, g:esearch#out#win#open)

  " Refresh match highlight
  setlocal ft=esearch
  if g:esearch.highlight_match
    if exists('b:esearch')
      try
        call matchdelete(b:esearch._match_highlight_id)
      catch /E803:/
      endtry
      unlet b:esearch
    endif
    let match_highlight_id = matchadd('ESearchMatch', a:opts.exp.vim_match, -1)
  endif

  augroup ESearchWinAutocmds
    au! * <buffer>
    for [func_name, event] in items(a:opts.request.events)
      exe printf('au User %s call esearch#out#win#%s()', event, func_name)
    endfor
    call esearch#backend#{a:opts.backend}#init_events()
  augroup END

  call s:init_mappings()
  call s:init_commands()

  let &iskeyword = g:esearch.wordchars
  setlocal noreadonly
  setlocal modifiable
  exe '1,$d'
  call setline(1, printf(s:header, 0))
  setlocal readonly
  setlocal nomodifiable
  setlocal noswapfile
  setlocal nonumber
  setlocal buftype=nofile
  setlocal bufhidden=hide

  let b:esearch = extend(a:opts, {
        \ 'prev_filename':       '',
        \ 'data_ptr':     0,
        \ '_columns':            {},
        \ '_match_highlight_id': match_highlight_id,
        \ '_last_update_time':   esearch#util#timenow(),
        \ '__broken_results':    [],
        \ 'errors':              [],
        \ 'data':                [],
        \ 'without':             function('esearch#util#without')
        \})
endfu

fu! s:find_or_create_buf(bufname, opencmd) abort
  let bufnr = bufnr('^'.a:bufname.'$')
  if bufnr == bufnr('%')
    return 0
  elseif bufnr > 0
    let buf_loc = s:find_buf(bufnr)
    if empty(buf_loc)
      silent exe a:opencmd.'|b ' . bufnr
    else
      silent exe 'tabn ' . buf_loc[0]
      exe buf_loc[1].'winc w'
    endif
  else
    silent  exe a:opencmd.'|file '.a:bufname
  endif
endfu

fu! s:find_buf(bufnr) abort
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

fu! esearch#out#win#trigger_key_press()
  " call feedkeys("\<Plug>(esearch-Nop)")
  call feedkeys("g\<ESC>", 'n')
endfu

fu! esearch#out#win#merge_data(data)
  let b:esearch.data += a:data
endfu

fu! esearch#out#win#update(...) abort
  let ignore_batches = a:0 && a:1

  let data = b:esearch.request.data
  let data_size = len(data)
  if data_size > b:esearch.data_ptr
    if ignore_batches || data_size - b:esearch.data_ptr - 1 <= g:esearch.batch_size
      let [from,to] = [b:esearch.data_ptr, data_size - 1]
      let b:esearch.data_ptr = data_size
    else
      let [from, to] = [b:esearch.data_ptr, b:esearch.data_ptr + g:esearch.batch_size - 1]
      let b:esearch.data_ptr += g:esearch.batch_size
    endif

    let parsed = esearch#adapter#{b:esearch.adapter}#parse_results(
          \ data, from, to, b:esearch.__broken_results, b:esearch.exp.vim)


    setlocal noreadonly
    setlocal modifiable
    call s:render_results(parsed)
    call setline(1, printf(s:header, b:esearch.data_ptr))
    setlocal readonly
    setlocal nomodifiable
    setlocal nomodified
  endif

  let b:esearch._last_update_time = esearch#util#timenow()
endfu

fu! s:render_results(parsed) abort
  let line = line('$') + 1
  let parsed = a:parsed

  let i = 0
  let limit = len(parsed)

  while i < limit
    let fname    = substitute(parsed[i].fname, b:esearch.cwd.'/', '', '')
    let context  = s:context(parsed[i].text)

    if fname !=# b:esearch.prev_filename
      call setline(line, '')
      let line += 1
      call setline(line, fname)
      let line += 1
    endif
    call setline(line, ' '.printf('%3d', parsed[i].lnum).' '.context)
    let b:esearch._columns[line] = parsed[i].col
    let b:esearch.prev_filename = fname
    let line += 1
    let i    += 1
  endwhile
endfu

fu! s:context(line)
  return esearch#util#btrunc(a:line,
                           \ match(a:line, b:esearch.exp.vim),
                           \ g:esearch.context_width.l,
                           \ g:esearch.context_width.r)
endfu

fu! esearch#out#win#map(lhs, rhs) abort
  let s:mappings[a:lhs] = '<Plug>(esearch-'.a:rhs.')'
endfu

fu! s:init_commands() abort
  let s:win = {
        \ 'line_number':   function('s:line_number'),
        \ 'open':          function('s:open'),
        \ 'filename':      function('s:filename'),
        \ 'is_file_entry': function('s:is_file_entry')
        \}
  command! -nargs=1 -range=0 -bar -buffer ESubstitute
        \ call esearch#substitute#do(<q-args>, <line1>, <line2>, s:win)

  if exists(':E') != 2
    command! -nargs=1 -range=0 -bar -buffer E
          \ call esearch#substitute#do(<q-args>, <line1>, <line2>, s:win)
  elseif exists(':ES') != 2
    command! -nargs=1 -range=0 -bar -buffer ES
          \ call esearch#substitute#do(<q-args>, <line1>, <line2>, s:win)
  endif
endfu

fu! s:init_mappings() abort
  nnoremap <silent><buffer> <Plug>(esearch-tab)           :<C-U>call <sid>open('tabnew')<cr>
  nnoremap <silent><buffer> <Plug>(esearch-tab-silent)    :<C-U>call <SID>open('tabnew', 'tabprevious')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-split)         :<C-U>call <SID>open('new')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-split-silent)  :<C-U>call <SID>open('new', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-vsplit)        :<C-U>call <SID>open('vnew')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-vsplit-silent) :<C-U>call <SID>open('vnew', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-open)          :<C-U>call <SID>open('edit')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-reload)        :<C-U>call esearch#init(b:esearch)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-prev)          :<C-U>sil exe <SID>jump(0)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-next)          :<C-U>sil exe <SID>jump(1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-prev-file)     :<C-U>sil cal <SID>file_jump(0)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-next-file)     :<C-U>sil cal <SID>file_jump(1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-Nop)           <Nop>

  call extend(s:mappings, s:default_mappings, 'keep')
  for map in keys(s:mappings)
    exe 'nmap <buffer> ' . map . ' ' . s:mappings[map]
  endfor
endfu

fu! s:open(cmd, ...) abort
  let fname = s:filename()
  if !empty(fname)
    let ln = s:line_number()
    let col = get(b:esearch._columns, line('.'), 1)
    let cmd = (a:0 ? 'noautocmd ' :'') . a:cmd
    try
      " See NOTE 1
      unsilent exe a:cmd . ' ' . fnameescape(b:esearch.cwd . '/' . fname)
    catch /E325:/
      " ignore warnings about swapfiles (let user and #substitute handle them)
    catch
      unsilent echo v:exception . ' at ' . v:throwpoint
    endtry

    call cursor(ln, col)
    norm! zz
    if a:0 | exe a:1 | endif
  endif
endfu

fu! s:filename() abort
  let pattern = s:filename_pattern . '\%>2l'
  let lnum = search(pattern, 'bcWn')
  if lnum == 0
    let lnum = search(pattern, 'cWn')
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

fu! s:file_jump(downwards) abort
  let pattern = s:filename_pattern . '\%>2l'

  if a:downwards
    if !search(pattern, 'W') && !s:is_filename()
      call search(pattern,  'Wbe')
    endif
  else
    if !search(pattern,  'Wbe') && !s:is_filename()
      call search(pattern, 'W')
    endif
  endif
endfu

fu! s:jump(downwards) abort
  let pattern = s:file_entry_pattern
  let last_line = line('$')

  if a:downwards
    " If one result - move cursor on it, else - move the next
    " bypassing the first entry line
    let pattern .= last_line <= 4 ? '\%>3l' : '\%>4l'
    call search(pattern, 'W')
  else
    " If cursor is in gutter between result groups(empty line)
    if '' ==# getline(line('.'))
      call search(pattern, 'Wb')
    endif
    " If no results behind - jump the first, else - previous
    call search(pattern, line('.') < 4 ? '' : 'Wbe')
  endif

  call search('^', 'Wb', line('.'))
  " If there is no results - do nothing
  if last_line == 1
    return ''
  else
    " search the start of the line
    return 'norm! ww'
  endif
endfu

fu! s:is_file_entry()
  return getline(line('.')) =~# s:file_entry_pattern
endfu

fu! s:is_filename()
  return getline(line('.')) =~# s:filename_pattern
endfu

fu! esearch#out#win#finish() abort
  au! ESearchWinAutocmds * <buffer>
  for [func_name, event] in items(b:esearch.request.events)
    exe printf('au! ESearchWinAutocmds User %s ', event)
  endfor

  let ignore_batches = 1
  call esearch#out#win#update(ignore_batches)

  unlet b:esearch.prev_filename b:esearch.data_ptr  b:esearch._last_update_time

  setlocal noreadonly
  setlocal modifiable

  if has_key(b:esearch.request, 'errors') && len(b:esearch.request.errors)
    call setline(1, 'ERRORS (' .len(b:esearch.request.errors).')')
    let line = 2
    for err in b:esearch.request.errors
      call setline(line, "\t".err)
      let line += 1
    endfor
    " norm! gggqG
  else
    call setline(1, getline(1) . '. Finished.' )
  endif

  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified
endfu
