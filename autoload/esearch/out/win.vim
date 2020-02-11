" We expect to receive the following if use #substitute#do over files with an
" NOTE 1 (unsilent when opening files)
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

let s:Vital    = vital#esearch#new()
let s:Promise  = s:Vital.import('Async.Promise')

let s:mappings = [
      \ {'lhs': 't',       'rhs': '<Plug>(esearch-win-tab)', 'default': 1},
      \ {'lhs': 'T',       'rhs': '<Plug>(esearch-win-tab-silent)', 'default': 1},
      \ {'lhs': 'i',       'rhs': '<Plug>(esearch-win-split)', 'default': 1},
      \ {'lhs': 'I',       'rhs': '<Plug>(esearch-win-split-silent)', 'default': 1},
      \ {'lhs': 's',       'rhs': '<Plug>(esearch-win-vsplit)', 'default': 1},
      \ {'lhs': 'S',       'rhs': '<Plug>(esearch-win-vsplit-silent)', 'default': 1},
      \ {'lhs': 'R',       'rhs': '<Plug>(esearch-win-reload)', 'default': 1},
      \ {'lhs': '<Enter>', 'rhs': '<Plug>(esearch-win-open)', 'default': 1},
      \ {'lhs': 'o',       'rhs': '<Plug>(esearch-win-open)', 'default': 1},
      \ {'lhs': '<C-n>',   'rhs': '<Plug>(esearch-win-next)', 'default': 1},
      \ {'lhs': '<C-p>',   'rhs': '<Plug>(esearch-win-prev)', 'default': 1},
      \ {'lhs': '<S-j>',   'rhs': '<Plug>(esearch-win-next-file)', 'default': 1},
      \ {'lhs': '<S-k>',   'rhs': '<Plug>(esearch-win-prev-file)', 'default': 1},
      \ ]

let s:RESULT_LINE_PATTERN = '^\%>1l\s\+\d\+.*'
" The first line. It contains information about the number of results
let s:file_entry_pattern = '^\s\+\d\+\s\+.*'
let s:filename_pattern = '^[^ ]' " '\%>2l'
let s:lines_map_padding = 0 " to index with line numbers which start from 1
if esearch#util#has_unicode()
  let s:spinner = g:esearch#unicode#spinner
else
  let s:spinner = ['.', '..', '...']
endif
let s:spinner_frames_size = len(s:spinner)
let s:spinner_slowdown = 2
let s:spinner_max_frame_size = max(map(copy(s:spinner), 'strchars(v:val)'))
let s:request_finished_header = 'Matches in %3d line(s), %3d%-'.s:spinner_max_frame_size.'s file(s)'
let s:header = 'Matches in %d%-'.s:spinner_max_frame_size.'sline(s), %d%-'.s:spinner_max_frame_size.'s file(s)'
let s:finished_header = 'Matches in %d %s, %d %s. Finished.'

if get(g:, 'esearch#out#win#keep_fold_gutter', 0)
  let s:blank_line_fold = 0
else
  let s:blank_line_fold = '<1'
endif

if !exists('g:esearch_win_context_syntax_async')
  let g:esearch_win_context_syntax_async = 1
endif
if !exists('g:esearch_win_disable_context_highlights_on_files_count')
  let g:esearch_win_disable_context_highlights_on_files_count = 50
endif
if !exists('g:esearch_win_update_using_timer')
  let g:esearch_win_update_using_timer = 1
endif
if !exists('g:esearch_win_update_timer_wait_time')
  let g:esearch_win_update_timer_wait_time = 100
endif
if !exists('g:esearch#out#win#context_syntax_highlight')
  let g:esearch#out#win#context_syntax_highlight = 1
endif
if !exists('g:esearch#out#win#context_syntax_max_lines')
  let g:esearch#out#win#context_syntax_max_lines = 500
endif

let s:context_syntaxes = {
      \ 'c':               'win_context_c',
      \ 'sh':              'win_context_sh',
      \ 'javascript':      'win_context_javascript',
      \ 'javascriptreact': 'win_context_javascript',
      \ 'php':             'win_context_php',
      \ 'go':              'win_context_go',
      \ 'ruby':            'win_context_ruby',
      \ 'html':            'win_context_html',
      \ 'java':            'win_context_java',
      \ 'python':          'win_context_python',
      \}

if !has_key(g:, 'esearch#out#win#open')
  let g:esearch#out#win#open = 'tabnew'
endif
if !has_key(g:, 'esearch#out#win#buflisted')
  let g:esearch#out#win#buflisted = 0
endif

" TODO wrap arguments with hash
fu! esearch#out#win#init(opts) abort
  call s:find_or_create_buf(a:opts.title, g:esearch#out#win#open)

  " Stop previous search process first
  if has_key(b:, 'esearch')
    call esearch#backend#{b:esearch.backend}#abort(bufnr('%'))
    if has_key(b:esearch, 'timer_id')
      call timer_stop(b:esearch.timer_id)
    endif
  end

  " Refresh match highlight
  setlocal ft=esearch
  if g:esearch.highlight_match
    if exists('b:esearch') && b:esearch._match_highlight_id > 0
      try
        call matchdelete(b:esearch._match_highlight_id)
      catch /E803:/
      endtry
      unlet b:esearch
    endif
    let match_highlight_id = matchadd('esearchMatch', a:opts.exp.vim_match, -1)
  else
    let match_highlight_id = -1
  endif

  if a:opts.request.async
    call s:init_update_events(a:opts)
  endif

  call s:init_mappings()
  call s:init_commands()

  setlocal modifiable
  exe '1,$d_'
  call esearch#util#setline(bufnr('%'), 1, printf(s:header, 0, '', 0, ''))
  setlocal undolevels=-1 " Disable undo
  setlocal nomodifiable
  setlocal nobackup
  setlocal noswapfile
  setlocal nonumber
  setlocal norelativenumber
  setlocal nospell
  setlocal nolist " prevent listing traling spaces on blank lines
  setlocal nomodeline
  let &buflisted = g:esearch#out#win#buflisted
  setlocal foldcolumn=0
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal foldlevel=2
  setlocal foldmethod=syntax
  setlocal foldtext=esearch#out#win#foldtext()
  syntax sync minlines=100

  let b:esearch = extend(a:opts, {
        \ 'files_count':            0,
        \ 'max_lines_found':        0,
        \ 'ignore_batches':         0,
        \ 'highlight_viewport':     0,
        \ 'tick':                   0,
        \ 'columns_map':            {},
        \ 'contexts':               [],
        \ 'context_ids_map':        [],
        \ '_match_highlight_id':    match_highlight_id,
        \ 'broken_results':         [],
        \ 'errors':                 [],
        \ 'data':                   [],
        \ 'context_syntax_regions': {},
        \ 'context_syntax_enabled': 1,
        \ 'without':                function('esearch#util#without')
        \})

  " setup null context for header
  call s:add_context(b:esearch.contexts, '', 1)
  let null_context = b:esearch.contexts[-1]
  let b:esearch.context_ids_map += [null_context.id, null_context.id]

  call extend(b:esearch.request, {
        \ 'bufnr':       bufnr('%'),
        \ 'data_ptr':    0,
        \ 'out_finish':  function('esearch#out#win#_is_render_finished')
        \})

  call esearch#backend#{b:esearch.backend}#run(b:esearch.request)


  if !b:esearch.request.async
    call esearch#out#win#finish(bufnr('%'))
  endif
endfu

fu! s:init_update_events(opts) abort
  if g:esearch_win_update_using_timer && exists('*timer_start')
    let a:opts.timer_id = timer_start(
          \ g:esearch_win_update_timer_wait_time,
          \ function('s:update_by_timer_callback',
          \ [bufnr('%')]),
          \ {'repeat': -1})
    let a:opts.update_with_timer_start = 1

    augroup ESearchWinAutocmds
      au! * <buffer>
      call esearch#backend#{a:opts.backend}#init_events()
    augroup END
  else
    augroup ESearchWinAutocmds
      au! * <buffer>
      " Events can be: update, finish etc.
      for [func_name, event] in items(a:opts.request.events)
        exe printf('au User %s call esearch#out#win#%s(%s)', event, func_name, string(bufnr('%')))
      endfor
      call esearch#backend#{a:opts.backend}#init_events()
    augroup END
    let a:opts.update_with_timer_start = 0
  endif
endfu

let g:debug = []

fu! s:update_by_timer_callback(bufnr, timer) abort
  let esearch = esearch#out#win#update(a:bufnr)

  if esearch isnot# 0
    let request = esearch.request
  else
    return 0
  endif

  if request.finished && len(request.data) == request.data_ptr
    call esearch#out#win#forced_finish(a:bufnr)
    call timer_stop(a:timer)
  endif
endfu

" TODO
fu! s:find_or_create_buf(bufname, opencmd) abort
  let escaped = s:escape_title(a:bufname)
  let escaped_for_bufnr = substitute(escape(a:bufname, '*?\{}[]'), '["]', '\\\\\0', 'g')

  if esearch#util#has_unicode()
    let escaped = substitute(escaped, '/', "\u2215", 'g')
    let escaped_for_bufnr = substitute(escaped_for_bufnr, '/', "\u2215", 'g')
  else
    let escaped_for_bufnr = substitute(escaped_for_bufnr, '/', '\\\\/', 'g')
    let escaped = substitute(escaped, '/', '\\\\/', 'g')
  endif

  let bufnr = bufnr('^'.escaped_for_bufnr.'$')
  " if current buffer
  if bufnr == bufnr('%')
    return 0
  " if buffer exists
  elseif bufnr > 0
    let buf_loc = esearch#util#bufloc(bufnr)
    if empty(buf_loc)
      silent exe 'bw ' . bufnr
      silent exe join(filter([a:opencmd, 'file '.escaped], '!empty(v:val)'), '|')
    else
      silent exe 'tabn ' . buf_loc[0]
      exe buf_loc[1].'winc w'
    endif
  " if buffer doesn't exists
  else
    silent exe join(filter([a:opencmd, 'file '.escaped], '!empty(v:val)'), '|')
  endif
endfu

fu! s:escape_title(title) abort
  let name = fnameescape(a:title)
  let name = substitute(name, '["]', '\\\\\0', 'g')
  return escape(name, '=')
endfu

fu! esearch#out#win#trigger_key_press(...) abort
  " call feedkeys("\<Plug>(esearch-Nop)")
  call feedkeys("g\<ESC>", 'n')
endfu

fu! esearch#out#win#update(bufnr) abort
  " prevent updates when outside of the window
  if a:bufnr != bufnr('%')
    return 0
  endif
  let esearch = getbufvar(a:bufnr, 'esearch')
  let ignore_batches = esearch.ignore_batches
  let request = esearch.request

  let data = esearch.request.data
  let data_size = len(data)

  call setbufvar(a:bufnr, '&ma', 1)
  if data_size > request.data_ptr
    if ignore_batches || data_size - request.data_ptr - 1 <= esearch.batch_size
      let [from, to] = [request.data_ptr, data_size - 1]
      let request.data_ptr = data_size
    else
      let [from, to] = [request.data_ptr, request.data_ptr + esearch.batch_size - 1]
      let request.data_ptr += esearch.batch_size
    endif

    let parsed = esearch.parse_results(data, from, to)
    call s:render_results(a:bufnr, parsed, esearch)
  endif

  let spinner = s:spinner[esearch.tick / s:spinner_slowdown % s:spinner_frames_size]
  if request.finished
    call esearch#util#setline(a:bufnr, 1, printf(s:request_finished_header,
          \ len(request.data),
          \ esearch.files_count,
          \ spinner
          \ ))
  else
    call esearch#util#setline(a:bufnr, 1, printf(s:header,
          \ len(request.data),
          \ spinner,
          \ esearch.files_count,
          \ spinner
          \ ))
  endif

  call setbufvar(a:bufnr, '&ma', 0)
  call setbufvar(a:bufnr, '&mod', 0)

  let esearch.tick += 1
  return esearch
endfu

fu! s:new_context(id, filename, start) abort
  return {'id': a:id, 'start': a:start, 'end': 0, 'filename': a:filename, 'filetype': 0, 'syntax_loaded': 0}
endfu

fu! s:null_context() abort
  return s:new_context(-1, '', 0)
endfu

fu! s:add_context(contexts, filename, start) abort
  let id = len(a:contexts)
  call add(a:contexts, s:new_context(id, a:filename, a:start))
endfu

fu! s:render_results(bufnr, parsed, esearch) abort
  let line = line('$') + 1
  let parsed = a:parsed

  let i = 0
  let limit = len(parsed)

  if has('win32')
    let sub_expression = substitute(a:esearch.cwd, '\\', '\\\\', 'g').'\\'
  else
    let sub_expression = a:esearch.cwd.'/'
  endif

  while i < limit
    let filename = substitute(parsed[i].filename, sub_expression, '', '')
    let text = esearch#util#ellipsize(
          \ parsed[i].text,
          \ parsed[i].col,
          \ a:esearch.context_width.left,
          \ a:esearch.context_width.right,
          \ g:esearch#util#ellipsis)

    if filename !=# a:esearch.contexts[-1].filename
      let a:esearch.contexts[-1].end = line

      if a:esearch.context_syntax_enabled && g:esearch#out#win#context_syntax_highlight
        if len(a:esearch.contexts) > g:esearch_win_disable_context_highlights_on_files_count
          let a:esearch.context_syntax_enabled = 0
          call s:unload_syntaxes(a:esearch)
        elseif 1 || len(a:esearch.contexts) > 10 && !a:esearch.highlight_viewport
          let a:esearch.highlight_viewport = 1
          call s:restrict_syntax_highlight_to_viewport(a:esearch)
        " TODO check why it slows down and probably drop loading syntax
        " synchronously
        " else
          " call s:load_syntax(a:esearch, a:esearch.contexts[-1])
        endif
      end

      call esearch#util#setline(a:bufnr, line, '')
      call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
      let line += 1

      call esearch#util#setline(a:bufnr, line, filename)
      call s:add_context(a:esearch.contexts, filename, line)
      call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
      let a:esearch.files_count += 1
      let line += 1
    endif

    call esearch#util#setline(a:bufnr, line, printf(' %3d %s', parsed[i].lnum, text))
    let a:esearch.columns_map[line] = parsed[i].col
    let a:esearch.contexts[-1].filename = filename
    call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
    let line += 1
    let i    += 1
  endwhile
endfu

fu! s:restrict_syntax_highlight_to_viewport(esearch) abort
  augroup ESearchWinViewportHighlight
    au! * <buffer>
    au CursorMoved <buffer> call s:highlight_viewport()
  augroup END
endfu

fu! s:highlight_viewport() abort
  let start = line('w0')
  let end   = line('w$')

  for context in b:esearch.contexts[b:esearch.context_ids_map[start] :]
    if !context.syntax_loaded
      call s:load_syntax(b:esearch, context)
    elseif context.start > end
      break
    endif
  endfor
endfu

fu! s:set_syntax_sync(esearch) abort
  if !g:esearch#out#win#context_syntax_highlight
        \ || a:esearch['max_lines_found'] < 1
    return
  endif

  syntax sync clear
  exe 'syntax sync minlines='.min([
        \ a:esearch['max_lines_found'],
        \ g:esearch#out#win#context_syntax_max_lines,
        \ ])
endfu

fu! s:blocking_load_syntax(esearch, context) abort
  if !g:esearch#out#win#context_syntax_highlight
    return
  endif

  if a:context.filetype is# 0
    let a:context.filetype = esearch#ftdetect#fast(a:context.filename)
  endif

  if !has_key(s:context_syntaxes, a:context.filetype)
    let a:context.syntax_loaded = -1
    return
  endif
  let syntax_name = s:context_syntaxes[a:context.filetype]

  if !has_key(a:esearch.context_syntax_regions, syntax_name)
    let a:esearch.context_syntax_regions[syntax_name] = {
          \ 'cluster': s:include_syntax_cluster(syntax_name),
          \ 'region_name': syntax_name,
          \ }
  endif

  let region = a:esearch.context_syntax_regions[syntax_name]
  exe printf('syntax region %s start="\%%%dl" end="\%%%dl" transparent contains=%s,esearchLineNr',
        \ region.region_name,
        \ a:context.start + 1,
        \ a:context.end,
        \ region['cluster'])
  let a:context.syntax_loaded = 1
endfu

fu! s:unload_syntaxes(esearch) abort
  let highlighted_contexts = []

  for name in map(values(a:esearch.context_syntax_regions), 'v:val.region_name')
    exe 'syn clear ' . name
  endfor
  augroup ESearchWinViewportHighlight
    au! * <buffer>
  augroup END
  syntax sync clear
  syntax sync maxlines=1

  let a:esearch.context_syntax_regions = {}
endfu

fu! s:load_syntax(esearch, context) abort
  if s:Promise.is_available() && g:esearch_win_context_syntax_async == 1
    let promise = s:Promise
          \.new({resolve -> timer_start(1, resolve)})
          \.then({-> s:blocking_load_syntax(a:esearch, a:context)})
          \.catch({reason -> execute('echoerr reason')})
  endif

  return s:blocking_load_syntax(a:esearch, a:context)
endfu

fu! s:include_syntax_cluster(ft) abort
  let cluster_name = '@' . toupper(a:ft)

  if exists('b:current_syntax')
    let syntax_save = b:current_syntax
    unlet b:current_syntax
  endif

  exe 'syntax include' cluster_name 'syntax/' . a:ft . '.vim'

  if exists('syntax_save')
    let b:current_syntax = syntax_save
  elseif exists('b:current_syntax')
    unlet b:current_syntax
  endif
  return cluster_name
endfu

fu! esearch#out#win#map(lhs, rhs) abort
  call esearch#util#add_map(s:mappings, a:lhs, '<Plug>(esearch-win-'.a:rhs.')')
endfu

fu! s:init_commands() abort
  let s:win = {
        \ 'line_in_file':   function('esearch#out#win#line_in_file'),
        \ 'open':          function('s:open'),
        \ 'filename':      function('esearch#out#win#filename'),
        \ 'is_file_entry': function('s:is_file_entry')
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

fu! s:init_mappings() abort
  nnoremap <silent><buffer> <Plug>(esearch-win-tab)           :<C-U>call <sid>open('tabnew')<cr>
  nnoremap <silent><buffer> <Plug>(esearch-win-tab-silent)    :<C-U>call <SID>open('tabnew', 'tabprevious')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split)         :<C-U>call <SID>open('new')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split-silent)  :<C-U>call <SID>open('new', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit)        :<C-U>call <SID>open('vnew')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit-silent) :<C-U>call <SID>open('vnew', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-open)          :<C-U>call <SID>open('edit')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-reload)        :<C-U>call esearch#init(b:esearch)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-prev)          :<C-U>sil exe <SID>jump(0, v:count1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-next)          :<C-U>sil exe <SID>jump(1, v:count1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-prev-file)     :<C-U>sil cal <SID>file_jump(0, v:count1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-next-file)     :<C-U>sil cal <SID>file_jump(1, v:count1)<CR>

  if esearch#preview#is_available()
    nnoremap <silent><buffer> <S-p> :<C-U>sil cal esearch#preview#start()<CR>
    nnoremap <silent><buffer> p     :<C-U>sil cal esearch#preview#start()<CR>
  endif

  for mapping in s:mappings
    if !g:esearch.default_mappings && mapping.default | continue | endif

    exe 'nmap <buffer> ' . mapping.lhs . ' ' . mapping.rhs
  endfor
endfu

fu! esearch#out#win#column_in_file() abort
  return get(b:esearch.columns_map, s:result_line(), 1)
endfu

fu! s:open(cmd, ...) abort
  let filename = esearch#out#win#filename()
  if !empty(filename)
    let ln = esearch#out#win#line_in_file()
    let col = esearch#out#win#column_in_file()
    let cmd = (a:0 ? 'noautocmd ' :'') . a:cmd
    try
      " See NOTE 1
      unsilent exe a:cmd . ' ' . fnameescape(b:esearch.cwd . '/' . filename)
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

fu! s:escape_filename(esearch, filename) abort
  let filename = matchstr(a:filename, '^\zs[^ ].*')
  let filename = substitute(filename, '^\./', '', '')

  return a:esearch.expand_filename(filename)
endfu

fu! esearch#out#win#filename() abort
  let pattern = s:filename_pattern . '\%>2l'
  let lnum = search(pattern, 'bcWn')
  if lnum == 0
    let lnum = search(pattern, 'cWn')
    if lnum == 0 | return '' | endif
  endif

  return s:escape_filename(b:esearch, getline(lnum))
endfu

fu! esearch#out#win#foldtext() abort
  let filename = getline(v:foldstart)
  let last_line = getline(v:foldend)
  let lines_count = v:foldend - v:foldstart - (empty(last_line) ? 1 : 0)

  let winwidth = winwidth(0) - &foldcolumn - (&number ? strwidth(string(line('$'))) + 1 : 0)
  let lines_count_str = lines_count . ' line(s)'

  let expansion = repeat('-', winwidth - strwidth(filename.lines_count_str))

  return filename . expansion . lines_count_str
endfu

fu! esearch#out#win#foldexpr() abort
  let line = getline(v:lnum)
  if line =~# s:file_entry_pattern || line =~# s:filename_pattern
    return 1
  endif
  return s:blank_line_fold
endfu

fu! s:result_line() abort
  let current_line_text = getline('.')
  let current_line = line('.')

  " if the cursor above the header on above a file
  if current_line < 3 || match(current_line_text, '^[^ ].*') >= 0
    return search(s:RESULT_LINE_PATTERN, 'cWn') " search forward
  elseif empty(current_line_text)
    return search(s:RESULT_LINE_PATTERN, 'bcWn')  " search backward
  else
    return current_line
  endif
endfu

fu! esearch#out#win#line_in_file() abort
  return matchstr(getline(s:result_line()), '^\s\+\zs\d\+\ze.*')
endfu

fu! s:file_jump(downwards, count) abort
  let pattern = s:filename_pattern . '\%>2l'
  let times = a:count

  while times > 0
    if a:downwards
      if !search(pattern, 'W') && !s:is_filename()
        call search(pattern,  'Wbe')
      endif
    else
      if !search(pattern,  'Wbe') && !s:is_filename()
        call search(pattern, 'W')
      endif
    endif
    let times -= 1
  endwhile
endfu

fu! s:jump(downwards, count) abort
  let pattern = s:file_entry_pattern
  let last_line = line('$')
  let times = a:count

  while times > 0
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
    let times -= 1
  endwhile

  call search('^', 'Wb', line('.'))
  " If there is no results - do nothing
  if last_line == 1
    return ''
  else
    " search the start of the line
    return 'norm! ww'
  endif
endfu

fu! s:is_file_entry() abort
  return getline(line('.')) =~# s:file_entry_pattern
endfu

fu! s:is_filename() abort
  return getline(line('.')) =~# s:filename_pattern
endfu

" Use this function for #backend#nvim. It has no truly async handlers, so data
" needs to be updated entirely (instantly or with BufEnter autocmd, if results
" buffer isn't current buffer)
fu! esearch#out#win#forced_finish(bufnr) abort
  if a:bufnr != bufnr('%')
    " Bind event to finish the search as soon as the buffer is enter
    exe 'aug ESearchWinAutocmds'
      let nr = string(a:bufnr)
      exe printf('au BufEnter <buffer=%s> call esearch#out#win#finish(%s)', nr, nr)
    aug END
    return 1
  else
    call esearch#out#win#finish(a:bufnr)
  endif
endfu

fu! esearch#out#win#finish(bufnr) abort
  " prevent updates when outside of the window
  if a:bufnr != bufnr('%')
    return 1
  endif
  let esearch = getbufvar(a:bufnr, 'esearch')

  if esearch.request.async && !esearch.update_with_timer_start
    exe printf('au! ESearchWinAutocmds * <buffer=%s>', string(a:bufnr))
    for event in values(esearch.request.events)
      exe printf('au! ESearchWinAutocmds User %s ', event)
    endfor
  endif

  " Update using all remaining request.data
  let esearch.ignore_batches = 1
  call esearch#out#win#update(a:bufnr)

  call s:set_syntax_sync(esearch)

  call setbufvar(a:bufnr, '&ma', 1)

  if esearch.request.status !=# 0 && (len(esearch.request.errors) || len(esearch.request.data))
    let errors = esearch.request.data + esearch.request.errors
    call esearch#util#setline(a:bufnr, 1, 'ERRORS from '.esearch.adapter.' ('.len(errors).')')
    let line = 2
    for err in errors
      call esearch#util#setline(a:bufnr, line, "\t".err)
      let line += 1
    endfor
  else
    call esearch#util#setline(a:bufnr, 1, printf(s:finished_header,
          \ len(esearch.columns_map),
          \ esearch#inflector#pluralize('line', len(esearch.columns_map)),
          \ esearch.files_count,
          \ esearch#inflector#pluralize('file', b:esearch.files_count),
          \))
  endif

  call setbufvar(a:bufnr, '&ma', 0)
  call setbufvar(a:bufnr, '&mod',   0)
endfu

" For some reasons s:_is_render_finished fails in Travis
fu! esearch#out#win#_is_render_finished() dict abort
  return self.data_ptr == len(self.data)
endfu
