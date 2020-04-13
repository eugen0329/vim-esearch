let s:Guard = vital#esearch#import('Vim.Guard')
let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()
let s:Promise       = vital#esearch#import('Async.Promise')
let s:List          = vital#esearch#import('Data.List')
let s:String        = vital#esearch#import('Data.String')
let s:Filepath      = vital#esearch#import('System.Filepath')
let s:Message       = vital#esearch#import('Vim.Message')
let s:BufferManager = vital#esearch#import('Vim.BufferManager')
let s:Buffer        = vital#esearch#import('Vim.Buffer')

let g:esearch#out#win#mappings = [
      \ {'lhs': 't',       'rhs': 'tab',                'default': 1},
      \ {'lhs': 'T',       'rhs': 'tab-silent',         'default': 1},
      \ {'lhs': 'o',       'rhs': 'split',              'default': 1},
      \ {'lhs': 'O',       'rhs': 'split-once-silent',  'default': 1},
      \ {'lhs': 's',       'rhs': 'vsplit',             'default': 1},
      \ {'lhs': 'S',       'rhs': 'vsplit-once-silent', 'default': 1},
      \ {'lhs': 'R',       'rhs': 'reload',             'default': 1},
      \ {'lhs': '<Enter>', 'rhs': 'open',               'default': 1},
      \ {'lhs': '<C-n>',   'rhs': 'next',               'default': 1},
      \ {'lhs': '<C-p>',   'rhs': 'prev',               'default': 1},
      \ {'lhs': '}',       'rhs': 'next-file',          'default': 1},
      \ {'lhs': '{',       'rhs': 'prev-file',          'default': 1},
      \ ]

let s:RESULT_LINE_PATTERN = '^\%>1l\s\+\d\+.*'
let s:entry_pattern = '^\s\+\d\+\s\+.*'
let s:filename_pattern = '^[^ ]' " '\%>2l'
let s:lines_map_padding = 0 " to index with line numbers which begin from 1
let g:esearch#out#win#result_text_regex_prefix = '\%>1l\%(\s\+\d\+\s.*\)\@<='
let s:linenr_format = ' %3d '
let s:t_func = type(function('tr'))

if get(g:, 'esearch#out#win#keep_fold_gutter', 0)
  let s:blank_line_fold = 0
else
  let s:blank_line_fold = '<1'
endif

if !exists('g:esearch_win_highlight_debounce_wait')
  let g:esearch_win_highlight_debounce_wait = 100
endif
if !exists('g:esearch_win_context_syntax_async')
  let g:esearch_win_context_syntax_async = 1
endif
if !exists('g:esearch_win_viewport_highlight_extend_by')
  let g:esearch_win_viewport_highlight_extend_by = 100
endif
if !exists('g:esearch_win_matches_highlight_debounce_wait')
  let g:esearch_win_matches_highlight_debounce_wait = 50
endif
if !exists('g:esearch_out_win_highlight_matches')
  let g:esearch_out_win_highlight_matches =
        \ (g:esearch#has#nvim_lua_syntax ? 'viewport' : 'matchadd')
endif
if !exists('g:esearch_win_disable_context_highlights_on_files_count')
  let g:esearch_win_disable_context_highlights_on_files_count =
        \ (g:esearch_out_win_highlight_matches ==# 'viewport' ? 800 : 200)
endif
if !exists('g:esearch_win_update_using_timer')
  let g:esearch_win_update_using_timer = 1
endif
if !exists('g:esearch_win_ellipsize_results')
  " TODO editing is not working with ellipsized results
  let g:esearch_win_ellipsize_results = 0
endif
if !exists('g:esearch_win_updates_timer_wait_time')
  let g:esearch_win_updates_timer_wait_time = 100
endif
if !exists('g:esearch#out#win#context_syntax_highlight')
  let g:esearch#out#win#context_syntax_highlight = 1
endif
if !exists('g:esearch#out#win#context_syntax_max_lines')
  let g:esearch#out#win#context_syntax_max_lines = 500
endif
if !exists('g:esearch_out_win_highlight_cursor_line_number')
  let g:esearch_out_win_highlight_cursor_line_number =
        \ g:esearch#has#virtual_cursor_linenr_highlight
endif
if !exists('g:esearch_out_win_render_using_lua')
  let g:esearch_out_win_render_using_lua = g:esearch#has#lua
endif
if !exists('g:esearch_out_win_nvim_lua_syntax')
  let g:esearch_out_win_nvim_lua_syntax = g:esearch_out_win_render_using_lua && g:esearch#has#nvim_lua_syntax
endif
if !exists('g:unload_context_syntax_on_line_length')
  let g:unload_context_syntax_on_line_length = 500
endif
if !exists('g:unload_global_syntax_on_line_length')
  let g:unload_global_syntax_on_line_length = 30000
endif
if !has_key(g:, 'esearch#out#win#open')
  let g:esearch#out#win#open = 'tabnew'
endif
if !has_key(g:, 'esearch#out#win#buflisted')
  let g:esearch#out#win#buflisted = 0
endif
if !has_key(g:, 'esearch_win_results_len_annotations')
  let g:esearch_win_results_len_annotations = has('nvim')
endif

let g:esearch#out#win#searches_with_stopped_highlights = esearch#cache#expiring#new({'max_age': 120, 'size': 1024})

fu! esearch#out#win#init(opts) abort
  call s:find_or_create_buf(a:opts.title, g:esearch#out#win#open)
  call esearch#util#doautocmd('User esearch_win_init_pre')

  call s:cleanup()

  let b:esearch = extend(a:opts, {
        \ 'bufnr':                    bufnr('%'),
        \ 'last_update_at':           reltime(),
        \ 'files_count':              0,
        \ 'separators_count':         0,
        \ 'mode':                     'normal',
        \ 'updates_timer':            -1,
        \ 'update_with_timer_start':  0,
        \ 'max_lines_found':          0,
        \ 'ignore_batches':           0,
        \ 'tick':                     0,
        \ 'line_numbers_map':         [],
        \ 'highlighted_lines_map':    {},
        \ 'contexts':                 [],
        \ 'context_by_name':          {},
        \ 'ctx_ids_map':              [],
        \ 'broken_results':           [],
        \ 'errors':                   [],
        \ 'context_syntax_regions':   {},
        \ 'highlights_enabled':       g:esearch#out#win#context_syntax_highlight,
        \ 'open':                     function('<SID>open'),
        \ 'filename':                 function('<SID>filename'),
        \ 'unescaped_filename':       function('<SID>unescaped_filename'),
        \ 'filetype':                 function('<SID>filetype'),
        \ 'line_in_file':             function('<SID>line_in_file'),
        \ 'ctx_view':                 function('<SID>ctx_view'),
        \ 'is_filename':              function('<SID>is_filename'),
        \ 'is_entry':                 function('<SID>is_entry'),
        \ 'jump2entry':               function('<SID>jump2entry'),
        \ 'jump2filename':            function('<SID>jump2filename'),
        \ 'is_current':               function('<SID>is_current'),
        \ 'is_blank':                 function('<SID>is_blank'),
        \ 'skip':                     0,
        \})
  let b:esearch = extend(a:opts, esearch#out#win#preview#floating#import())
  let b:esearch = extend(a:opts, esearch#out#win#preview#split#import())

  call esearch#out#win#header#init(b:esearch)

  let b:esearch = extend(a:opts, {
        \ 'windows_opened_once': {},
        \ 'opened_once_manager': s:BufferManager.new(),
        \ 'opened_manager':      s:BufferManager.new(),
        \}, 'keep')

  setl modifiable
  exe '1,$d_'
  call esearch#util#setline(bufnr('%'), 1, b:esearch.header_text())
  setl nomodifiable undolevels=-1 nobackup noswapfile nonumber norelativenumber
  setl nospell nowrap synmaxcol=400 nolist nomodeline foldcolumn=0 buftype=nofile bufhidden=hide
  setl foldmethod=marker foldtext=esearch#out#win#foldtext()
  let &buflisted = g:esearch#out#win#buflisted
  syntax sync minlines=100

  if b:esearch.request.async
    call s:init_update_events(b:esearch)
  endif

  " setup blank context for header
  call esearch#out#win#add_context(b:esearch.contexts, '', 1)
  let header_context = b:esearch.contexts[0]
  let header_context.end = 2
  let b:esearch.ctx_ids_map += [header_context.id, header_context.id]
  let b:esearch.line_numbers_map += [0, 0]

  call extend(b:esearch.request, {
        \ 'bufnr':       bufnr('%'),
        \ 'cursor':      0,
        \ 'out_finish':  function('esearch#out#win#_is_render_finished')
        \})

  setl ft=esearch

  " Prevent from blinking of stopped highlights on reload etc.
  if g:esearch#out#win#searches_with_stopped_highlights.has(b:esearch.request.command)
    let b:esearch.highlights_enabled = 0
    if g:esearch_out_win_highlight_matches ==# 'viewport'
      call esearch#out#win#appearance#matches#init(b:esearch)
    endif
  else
    " Highlights should be set after setting the filetype as all the definitions
    " are inside syntax/esearch.vim
    call esearch#out#win#appearance#matches#init(b:esearch)
    if g:esearch#out#win#context_syntax_highlight
      call esearch#out#win#appearance#ctx_syntaxes#init(b:esearch)
    endif
    if g:esearch_out_win_highlight_cursor_line_number
      call esearch#out#win#appearance#cursor_linenr#init(b:esearch)
    endif
  endif
  if g:esearch_out_win_nvim_lua_syntax
    call luaeval('esearch.appearance.header()')
  endif

  " Some plugins set mappings on filetype, so they should be set after.
  " Other things can be conveniently redefined using au FileType esearch
  call s:init_mappings()
  call s:init_commands()

  aug esearch_win_event
    call esearch#util#doautocmd('User esearch_win_event')
  aug END
  call esearch#util#doautocmd('User esearch_win_init_post')

  call esearch#backend#{b:esearch.backend}#run(b:esearch.request)

  if !b:esearch.request.async
    call esearch#out#win#finish(bufnr('%'))
  endif
endfu

fu! s:open(...) abort dict
  " As autoload functions cannot handle dict as s:... functions do. Otherwise
  " it'd cause preblems with esearch#debounce#... methods
  return call('esearch#out#win#open#do', a:000, self)
endfu

" Is used to prevent problems with asynchronous code
fu! s:is_current() abort dict
  return get(b:, 'esearch', {}) ==# self
endfu

fu! s:is_blank() abort dict
  " if only a header ctx
  if len(self.contexts) < 2 | return s:true | endif
endfu

fu! s:cleanup() abort
  if exists('b:esearch')
    call esearch#backend#{b:esearch.backend}#abort(bufnr('%'))
    if has_key(b:esearch, 'updates_timer')
      call timer_stop(b:esearch.updates_timer)
    endif
    call esearch#out#win#appearance#matches#uninit(b:esearch)
    call esearch#out#win#appearance#ctx_syntaxes#uninit(b:esearch)
    call esearch#out#win#appearance#cursor_linenr#uninit(b:esearch)
  endif

  call esearch#option#reset()
  aug esearch_win_event
    au! * <buffer>
  aug END
  aug esearch_win_modifiable
    au! * <buffer>
  aug END
  call esearch#changes#unlisten_for_current_buffer()

  call esearch#util#doautocmd('User esearch_win_uninit_post')
endfu

" TODO refactoring
fu! s:init_update_events(esearch) abort
  if g:esearch_win_update_using_timer && has('timers')
    let a:esearch.update_with_timer_start = 1

    aug esearch_win_updates
      au! * <buffer>
      call esearch#backend#{a:esearch.backend}#init_events()

      if a:esearch.backend !=# 'vimproc'
        " TODO
        for [func_name, event] in items(a:esearch.request.events)
          let a:esearch.request.events[func_name] =
                \ function('s:update_by_backend_callbacks_until_1st_batch_is_rendered', [bufnr('%')])
        endfor
      endif

      let a:esearch.updates_timer = timer_start(
            \ g:esearch_win_updates_timer_wait_time,
            \ function('s:update_by_timer_callback', [a:esearch, bufnr('%')]),
            \ {'repeat': -1})
    aug END
  else
    let a:esearch.update_with_timer_start = 0

    aug esearch_win_updates
      au! * <buffer>
      call esearch#backend#{a:esearch.backend}#init_events()
    aug END
    for [func_name, event] in items(a:esearch.request.events)
      let a:esearch.request.events[func_name] = function('esearch#out#win#' . func_name, [bufnr('%')])
    endfor
  endif
endfu

" Is used to render the first batch as soon as possible before the first timer
" callback invokation. Is called on stdout event from a backend and is undloaded
" when the first batch is rendered. Will render <= 2 * batch_size entries
" (usually much less than 2x).
fu! s:update_by_backend_callbacks_until_1st_batch_is_rendered(bufnr) abort
  if a:bufnr != bufnr('%')
    return 1
  endif
  let esearch = getbufvar(a:bufnr, 'esearch')

  if esearch.request.cursor < esearch.batch_size
    call esearch#out#win#update(a:bufnr)

    if esearch.request.finished && len(esearch.request.data) == esearch.request.cursor
      call esearch#out#win#schedule_finish(a:bufnr)
    endif
  else
    call s:unload_update_events(esearch)
  endif
endfu

fu! s:unload_update_events(esearch) abort
  aug esearch_win_updates
    for func_name in keys(a:esearch.request.events)
      let a:esearch.request.events[func_name] = s:null
    endfor
  aug END
  exe printf('au! esearch_win_updates * <buffer=%d>', a:esearch.bufnr)
endfu

fu! s:update_by_timer_callback(esearch, bufnr, timer) abort
  " Timer counts time only from the begin, not from the return, so we have to
  " ensure it manually
  " TODO extract to a separate throttling lib
  let elapsed = reltimefloat(reltime(a:esearch.last_update_at)) * 1000
  if elapsed < g:esearch_win_updates_timer_wait_time
    return 0
  endif

  call esearch#out#win#update(a:esearch.bufnr)

  let request = a:esearch.request
  if request.finished && len(request.data) == request.cursor
    let a:esearch.updates_timer = -1
    call esearch#out#win#schedule_finish(a:esearch.bufnr)
    call timer_stop(a:timer)
  endif
endfu

" TODO customizability
fu! s:find_or_create_buf(bufname, opener) abort
  let escaped = a:bufname

  let safe_slash = g:esearch#has#unicode ? g:esearch#unicode#division_slash : '{slash}'
  let escaped = substitute(escaped, '/', safe_slash, 'g')

  let bufnr = esearch#buf#find(escaped)
  " Noop if the buffer is current
  if bufnr == bufnr('%') | return | endif
  " Open if doesn't exist
  if bufnr == -1
    return s:Buffer.open(escaped, {'opener': a:opener})
  endif
  let [tabnr, winnr] = esearch#buf#location(bufnr)
  " Open if closed
  if empty(winnr)
    return s:Buffer.open(escaped, {'opener': a:opener})
  endif
  " Locate if opened
  silent exe 'tabnext ' . tabnr
  exe winnr . 'wincmd w'
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

fu! esearch#out#win#update(bufnr, ...) abort
  " prevent updates when outside of the window
  if a:bufnr != bufnr('%')
    return 0
  endif
  let esearch = getbufvar(a:bufnr, 'esearch')
  let ignore_batches = get(a:000, 0, esearch.ignore_batches)
  let request = esearch.request
  let data = esearch.request.data
  let data_size = len(data)

  call setbufvar(a:bufnr, '&ma', 1)
  if data_size > request.cursor
    " TODO consider to discard ignore_batches as it doesn't make a lot of sense
    if ignore_batches
          \ || data_size - request.cursor - 1 <= esearch.batch_size
          \ || (request.finished && data_size - request.cursor - 1 <= esearch.final_batch_size)
      let [from, to] = [request.cursor, data_size - 1]
      let request.cursor = data_size
    else
      let [from, to] = [request.cursor, request.cursor + esearch.batch_size - 1]
      let request.cursor += esearch.batch_size
    endif

    if g:esearch_out_win_render_using_lua
      call esearch#out#win#render#lua#do(a:bufnr, data, from, to, esearch)
    else
      call esearch#out#win#render#viml#do(a:bufnr, data, from, to, esearch)
    endif
  endif

  call esearch#util#setline(a:bufnr, 1, esearch.header_text())

  call setbufvar(a:bufnr, '&ma', 0)
  call setbufvar(a:bufnr, '&mod', 0)
  let esearch.last_update_at = reltime()
  let esearch.tick += 1
endfu

fu! s:new_context(id, filename, begin) abort
  return {
        \ 'id': a:id,
        \ 'begin': a:begin,
        \ 'end': 0,
        \ 'filename': a:filename,
        \ 'filetype': s:null,
        \ 'syntax_loaded': 0,
        \ 'lines': {},
        \ }
endfu

fu! esearch#out#win#add_context(contexts, filename, begin) abort
  let id = len(a:contexts)
  call add(a:contexts, s:new_context(id, a:filename, a:begin))
endfu

fu! esearch#out#win#stop_highlights(reason) abort
  if g:esearch#out#win#context_syntax_highlight || g:esearch_out_win_highlight_matches !=# 'viewport'
    echomsg 'esearch: some highlights are disabled to prevent slowdowns (reason: ' . a:reason . ')'
  endif

  call esearch#out#win#appearance#cursor_linenr#soft_stop(b:esearch)
  call esearch#out#win#appearance#ctx_syntaxes#soft_stop(b:esearch)
  if g:esearch_out_win_highlight_matches !=# 'viewport'
    call esearch#out#win#appearance#matches#soft_stop(b:esearch)
  endif
  call g:esearch#out#win#searches_with_stopped_highlights.set(b:esearch.request.command, 1)
endfu

fu! esearch#out#win#map(lhs, rhs) abort
  call esearch#util#add_map(g:esearch#out#win#mappings, a:lhs, a:rhs)
endfu

fu! s:init_commands() abort
  command! -nargs=1 -range=0 -bar -buffer  -complete=custom,esearch#substitute#complete ESubstitute
        \ call esearch#substitute#do(<q-args>, <line1>, <line2>, b:esearch)

  if exists(':E') != 2
    command! -nargs=1 -range=0 -bar -buffer -complete=custom,esearch#substitute#complete E
          \ call esearch#substitute#do(<q-args>, <line1>, <line2>, b:esearch)
  elseif exists(':ES') != 2
    command! -nargs=1 -range=0 -bar -buffer  -complete=custom,esearch#substitute#complete ES
          \ call esearch#substitute#do(<q-args>, <line1>, <line2>, b:esearch)
  endif
endfu

fu! s:init_mappings() abort
  nnoremap <silent><buffer> <Plug>(esearch-win-tab)                :<C-U>cal b:esearch.open('tabnew')<cr>
  nnoremap <silent><buffer> <Plug>(esearch-win-tab-silent)         :<C-U>cal b:esearch.open('tabnew', {'stay': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split-once)         :<C-U>cal b:esearch.open('new', {'once': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split-once-silent)  :<C-U>cal b:esearch.open('new', {'stay': 1, 'once': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split)              :<C-U>cal b:esearch.open('new')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split-silent)       :<C-U>cal b:esearch.open('new', {'stay': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit-once)        :<C-U>cal b:esearch.open('vnew', {'once': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit-once-silent) :<C-U>cal b:esearch.open('vnew', {'stay': 1, 'once': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit)             :<C-U>cal b:esearch.open('vnew')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit-silent)      :<C-U>cal b:esearch.open('vnew', {'stay': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-open)               :<C-U>cal b:esearch.open('edit')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-prev)               :<C-U>cal b:esearch.jump2entry('^', v:count1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-next)               :<C-U>cal b:esearch.jump2entry('v', v:count1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-prev-file)          :<C-U>cal b:esearch.jump2filename('^', v:count1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-next-file)          :<C-U>cal b:esearch.jump2filename('v', v:count1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-reload)             :<C-U>cal esearch#init(b:esearch)<CR>

  if g:esearch#has#preview
    nnoremap <silent><buffer> <S-p> :<C-U>call b:esearch.preview_enter()<CR>
    nnoremap <silent><buffer> p     :<C-U>call b:esearch.preview_zoom()<CR>
  else
    nnoremap <silent><buffer> <S-p> :<C-U>call b:esearch.split_preview('vnew', {'stay': 0})<CR>
    nnoremap <silent><buffer> p     :<C-U>call b:esearch.split_preview('vnew')<CR>
  endif

  for i in range(0, len(g:esearch#out#win#mappings) - 1)
    if !g:esearch.default_mappings && g:esearch#out#win#mappings[i].default | continue | endif

    if type(g:esearch#out#win#mappings[i].rhs) ==# s:t_func
      exe 'nnoremap <buffer><silent> ' . g:esearch#out#win#mappings[i].lhs
            \ . ' :<C-u>call <SID>invoke_mapping_callback(' . i . ')<CR>'
    else
      exe 'nmap <buffer> ' . g:esearch#out#win#mappings[i].lhs
            \ . ' <Plug>(esearch-win-' . g:esearch#out#win#mappings[i].rhs . ')'
    endif
  endfor
  " TODO handle start via mappings
  " exe 'nmap <buffer> m :<C-U>sil cal esearch#out#win#edit()<CR>'
endfu

fu! s:invoke_mapping_callback(i) abort
  call g:esearch#out#win#mappings[a:i].rhs(b:esearch)
endfu

" Returns dict that can be forwarded into builtin winrestview()
fu! s:ctx_view() abort dict
  let line = self.line_in_file()
  let state = esearch#out#win#_state(self)
  let linenr = printf(s:linenr_format, state.line_numbers_map[line('.')])
  return { 'lnum': line,  'col': max([0, col('.') - strlen(linenr) - 1]) }
endfu

fu! s:line_in_file() abort dict
  return (matchstr(getline(s:result_line()), '^\s\+\zs\d\+\ze.*'))
endfu

fu! s:filetype(...) abort dict
  if !self.is_current() | return | endif

  let ctx = s:file_context_at(line('.'), self)
  if empty(ctx) | return s:null | endif

  if empty(ctx.filetype)
    let opts = get(a:000)

    if get(opts, 'fast', 0)
      let ctx.filetype = esearch#ftdetect#complete(ctx.filename)
    else
      let ctx.filetype = esearch#ftdetect#fast(ctx.filename)
    endif
  endif

  return ctx.filetype
endfu

fu! s:unescaped_filename() abort dict
  if !self.is_current() | return | endif

  let ctx = s:file_context_at(line('.'), self)
  if empty(ctx) | return s:null | endif

  if s:Filepath.is_absolute(ctx.filename)
    let filename = ctx.filename
  else
    let filename = s:Filepath.join(self.cwd, ctx.filename)
  endif

  return filename
endfu

fu! s:filename() abort dict
  if !self.is_current() | return | endif

  return fnameescape(self.unescaped_filename())
endfu

fu! s:file_context_at(line, esearch) abort
  if a:esearch.is_blank() | return s:null | endif

  let ctx = esearch#out#win#repo#ctx#new(a:esearch, esearch#out#win#_state(a:esearch))
        \.by_line(a:line)
  if ctx.id == 0
    return a:esearch.contexts[1]
  endif

  return ctx
endfu

fu! esearch#out#win#_state(esearch) abort
  if a:esearch.mode ==# 'normal'
    " Probably a better idea would be to return only paris, stored in states.
    " Storing in normal mode within undotree with a single node is not the best
    " option as it seems to create extra overhead during #update call
    " (especially on searches with thousands results; according to profiling).
    return a:esearch
  else
    return a:esearch.undotree.head.state
  endif
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

fu! s:jump2filename(direction, count) abort dict
  let pattern = s:filename_pattern . '\%>2l'
  let times = a:count

  if a:direction ==# 'v'
    while times > 0
      if !search(pattern, 'W') && !self.is_filename()
        call search(pattern,  'Wbe')
      endif
      let times -= 1
    endwhile
  else
    while times > 0
      if !search(pattern,  'Wbe') && !self.is_filename()
        call search(pattern, 'W')
      endif
      let times -= 1
    endwhile
  endif

  return 1
endfu

fu! s:jump2entry(direction, count) abort dict
  if self.is_blank()
    return 0
  endif

  let pattern = s:entry_pattern
  let times = a:count

  " When jumping down from the header context, it locates the second entry as
  " clicking on the header cause opening the first encountered entry below.
  if a:direction ==# 'v'
    let pattern .= line('$') <= 4 ? '\%>3l' : '\%>4l'

    while times > 0
      call search(pattern, 'W')
      let times -= 1
    endwhile
  else
    " When jumping up from the header context, it locates the first entry below
    if line('.') <= 3
      call search(pattern, 'W')
    else
      let pattern .= '\%<'.line('.').'l'
      while times > 0
        call search(pattern,  'Wb')
        let times -= 1
      endwhile
    endif
  endif

  " Locate the first column (including virtual) after a line number
  norm! 0
  let pos = searchpos('\s\+\d\+\s', 'Wne')
  call cursor(pos[0], pos[1] + 1)

  return 1
endfu

fu! s:is_entry() abort dict
  return getline(line('.')) =~# s:entry_pattern
endfu

fu! s:is_filename() abort dict
  return getline(line('.')) =~# s:filename_pattern
endfu

fu! esearch#out#win#schedule_finish(bufnr) abort
  if a:bufnr != bufnr('%')
    " Bind event to finish the search as soon as the buffer is entered
    aug esearch_win_updates
      exe printf('au BufEnter <buffer=%d> ++once call esearch#out#win#finish(%d)', a:bufnr, a:bufnr)
    aug END
    return 1
  else
    call esearch#out#win#finish(a:bufnr)
  endif
endfu

fu! esearch#out#win#finish(bufnr) abort
  " prevent updates when outside of the buffer
  if a:bufnr != bufnr('%')
    return 1
  endif

  call esearch#util#doautocmd('User esearch_win_finish_pre')
  let esearch = getbufvar(a:bufnr, 'esearch')

  call esearch#out#win#update(a:bufnr, 1)
  " TODO
  let esearch.contexts[-1].end = line('$')
  if g:esearch_win_results_len_annotations
    call luaeval('esearch.appearance.set_context_len_annotation(_A[1], _A[2])',
          \ [esearch.contexts[-1].begin, len(esearch.contexts[-1].lines)])
  endif

  if esearch.request.async
    exe printf('au! esearch_win_updates * <buffer=%s>', string(a:bufnr))
  endif

  if has_key(esearch, 'updates_timer')
    call timer_stop(esearch.updates_timer)
  endif
  call setbufvar(a:bufnr, '&modifiable', 1)

  if !esearch.current_adapter.is_success(esearch.request)
    call esearch#stderr#finish(esearch)
  endif

  let esearch.header_text = function('esearch#out#win#header#finished_render')
  call esearch#util#setline(a:bufnr, 1, esearch.header_text())

  call setbufvar(a:bufnr, '&ma', 0)
  call setbufvar(a:bufnr, '&mod',   0)

  call esearch#out#win#edit()

  if g:esearch_out_win_nvim_lua_syntax
    call luaeval('esearch.appearance.buf_attach_ui()')
  endif

  if g:esearch_win_results_len_annotations
    call esearch#out#win#appearance#annotations#init(esearch)
  endif
endfu

" For some reasons s:_is_render_finished fails in Travis
fu! esearch#out#win#_is_render_finished() dict abort
  return self.cursor == len(self.data)
endfu

fu! esearch#out#win#edit() abort
  let b:esearch.mode = 'edit'
  let v:errors = []
  setl modifiable
  setl undolevels=1000
  setl noautoindent nosmartindent " problems with insert
  setl formatoptions=
  setl noswapfile

  set buftype=acwrite
  aug esearch_win_modifiable
    au! * <buffer>
    au BufWriteCmd <buffer> call s:write()
  aug END

  let b:esearch.undotree = esearch#undotree#new({
        \ 'ctx_ids_map': b:esearch.ctx_ids_map,
        \ 'line_numbers_map': b:esearch.line_numbers_map,
        \ })
  call esearch#changes#listen_for_current_buffer(b:esearch.undotree)
  call esearch#changes#add_observer(function('esearch#out#win#handle_changes'))

  call esearch#option#make_local_to_buffer('backspace', 'indent,start', 'InsertEnter')
  set nomodified

  call esearch#compat#visual_multi#init()
  call esearch#compat#multiple_cursors#init()
endfu

fu! s:write() abort
  let parsed = esearch#out#win#parse#entire()
  if has_key(parsed, 'error')
    throw parsed.error
  endif

  let diff = esearch#out#win#diff#do(parsed.contexts, b:esearch.contexts[1:])

  if diff.statistics.files == 0
    echo 'Nothing to save'
    return
  endi

  let lines_stats = []
  let changes_count = 0
  if diff.statistics.modified > 0
    let changes_count += diff.statistics.modified
    let lines_stats += [diff.statistics.modified . ' modified']
  endif
  if diff.statistics.deleted > 0
    let changes_count += diff.statistics.deleted
    let lines_stats += [diff.statistics.deleted . ' deleted']
  endif
  let files_stats_text = printf(' %s %s %d %s',
        \ (len(lines_stats) > 1 ? 'lines' : esearch#util#pluralize('line', changes_count)),
        \ (diff.statistics.files > 1 ? 'across' : 'inside'),
        \ diff.statistics.files,
        \ esearch#util#pluralize('file', diff.statistics.files),
        \ )
  let message = 'Write changes? (' . join(lines_stats, ', ') . files_stats_text . ')'

  if esearch#ui#confirm#show(message, ['Yes', 'No']) == 1
    call esearch#writer#buffer#write(diff, b:esearch)
  endif
endfu

fu! esearch#out#win#handle_changes(event) abort
  if a:event.id =~# '^n-motion' || a:event.id =~# '^n-change'
        \  || a:event.id =~# '^v-delete' || a:event.id =~# '^V-line-delete'
        \  || a:event.id =~# '^V-line-change'
    call esearch#out#win#delete_multiline#handle(a:event)
  elseif a:event.id =~# 'undo'
    call s:handle_undo_traversal(a:event)
  elseif a:event.id =~# 'n-inline-paste' || a:event.id =~# 'n-inline-repeat-gn'
        \ || a:event.id =~# 'n-inline\d\+' || a:event.id =~# 'v-inline'
    let debug = s:handle_normal__inline(a:event)
  elseif a:event.id =~# 'i-inline'
    let debug = s:handle_insert__inline(a:event)
  elseif  a:event.id =~# 'i-delete-newline'
    let debug = s:handle_insert__delete_newlines(a:event)
  elseif  a:event.id =~# 'blockwise-visual'
    call esearch#out#win#blockwise_visual#handle(a:event)
  elseif  a:event.id =~# 'i-add-newline'
    call s:handle_insert__add_newlines(a:event)
  elseif a:event.id =~# 'join'
    call esearch#out#win#unsupported#handle(a:event)
  elseif a:event.id =~# 'cmdline'
    call esearch#out#win#cmdline#handle(a:event)
  else
    call esearch#out#win#unsupported#handle(a:event)
  endif

  if g:esearch#env isnot 0
    call assert_equal(line('$') + 1, len(b:esearch.undotree.head.state.ctx_ids_map))
    call assert_equal(line('$') + 1, len(b:esearch.undotree.head.state.line_numbers_map))
    let a:event.errors = len(v:errors)
    " call esearch#debug#log(a:event,  len(v:errors))
  endif
endfu

fu! s:handle_undo_traversal(event) abort
  call b:esearch.undotree.checkout(a:event.changenr, a:event.kind)
  call esearch#changes#rewrite_last_state({
        \ 'changenr': changenr(),
        \ })
endfu

fu! s:handle_insert__add_newlines(event) abort
  " using recorded original text is the only way to safely recover line1
  " contents as splitting line1 and line2 by col1 and col2 and joining them back
  " is unreliable when pasting huge amount of newlines or when using 3d party plugins
  call setline(a:event.line1, a:event.original_text)
  call deletebufline(bufnr('%'), a:event.line1 + 1, a:event.line2)
  call cursor(a:event.line1, a:event.col1)
  call esearch#changes#undo_state()
  if mode() ==# 'i'
    doau CursorMovedI
  else
    doau CursorMoved
  endif
endfu

fu! s:handle_insert__delete_newlines(event) abort
  let [line1, line2, col1, col2] = [a:event.line1, a:event.line2, a:event.col1, a:event.col2]

  if a:event.id ==# 'i-delete-newline-right'
    let text = getline(line1)

    if col1 < 2 " current line was blank
      call setline(line1, '')
      call append(line1, text)
    else
      call setline(line1, text[0: max([0, col1 - 2])])
      call append(line1, text[ col1 - 1 :])
    endif

    call esearch#changes#rewrite_last_state({
          \ 'current_line': text[ : max([0, col1 - 2]) ],
          \ 'line':         line1,
          \ 'size':         line('$'),
          \ })
  else
    let text = getline(line1)
    if col1 < 2 " previous line was blank
      call setline(line1, '')
    else
      call setline(line1, text[0: col1 - 2])
    endif
    call append(line1, text[ col1 - 1 :])
    call cursor(line2, 1)
    call esearch#changes#rewrite_last_state({
          \ 'current_line': text[ col1 - 1 :],
          \ 'line':         line2,
          \ 'size':         line('$'),
          \ 'col':          1,
          \ })
    if mode() ==# 'i'
      doau CursorMovedI
    else
      doau CursorMoved
    endif
  endif
  call b:esearch.undotree.synchronize()
endfu

fu! s:handle_insert__inline(event) abort
  let [line1, col1, col2] = [a:event.line1, a:event.col1, a:event.col2]
  let state   = deepcopy(b:esearch.undotree.head.state)
  let context = esearch#out#win#repo#ctx#new(b:esearch, state).by_line(line1)
  let text    = getline(line1)
  let linenr  = printf(' %3d ', state.line_numbers_map[line1])
  let cursorpos = []

  if line1 == 1
    call setline(line1, b:esearch.header_text())
  elseif line1 == 2 || line1 == context.end && context.end != line('$')
    let text = ''
    call setline(line1, text)
  elseif line1 == context.begin
    let text = context.filename
    call setline(line1, text)
  elseif line1 > 2 && col1 < strlen(linenr) + 1
    " VIRTUAL UI WITH LINE NUMBERS IS AFFECTED:

    if a:event.id ==# 'i-inline-add'
      " Recovered text:
      "   - take   linenr
      "   - concat with extracted chars inserted within a virtual ui
      "   - concat with the rest of the text with removed leftovers from
      "   virtual ui and inserted chars
      let text = linenr
            \ . text[col1 - 1 : col2 - 1]
            \ . text[strlen(linenr) + (col2 - col1 + 1) :]
      let cursorpos = [line1, strlen(linenr) + strlen(text[col1 - 1 : col2 - 1]) + 1]
    elseif a:event.id =~# 'i-inline-delete'
      " Recovered text:
      "   - take   linenr
      "   - concat with original text except linenr and deleted part on the beginning
      let text = linenr . a:event.original_text[ max([col2, strlen(linenr)]) : ]
      let cursorpos = [line1, strlen(linenr) + 1]
    else
      throw 'Unexpected' . string(a:event)
    endif

    call setline(line1, text)
  endif

  if !empty(cursorpos)
    call esearch#changes#rewrite_last_state({
          \ 'line': cursorpos[0],
          \ 'col':  cursorpos[1],
          \ })
    call cursor(cursorpos)
    if mode() ==# 'i'
      doau CursorMovedI
    else
      doau CursorMoved
    endif
  endif
  call esearch#changes#rewrite_last_state({ 'current_line': text })
  call b:esearch.undotree.synchronize()
endfu

fu! s:handle_normal__inline(event) abort
  " TODO will be refactored
  let [line1, col1, col2] = [a:event.line1, a:event.col1, a:event.col2]
  let state = b:esearch.undotree.head.state
  let context = esearch#out#win#repo#ctx#new(b:esearch, state).by_line(line1)

  let text = getline(line1)
  let linenr = printf(' %3d ', state.line_numbers_map[line1])

  if line1 == 1
    call setline(line1, b:esearch.header_text())
  elseif line1 == context.begin
    " it's a filename, restoring
    call setline(line1, context.filename)
  elseif line1 > 2 && col1 < strlen(linenr) + 1
    " VIRTUAL UI WITH LINE NUMBERS IS AFFECTED:

    if col2 < strlen(linenr) + 1 " deletion happened within linenr, the text is untouched
      " recover linenr and remove leading previous linenr leftover
      let text = linenr . text[strlen(linenr) - (col2 - col1 + 1) :]
    else " deletion starts within linenr, ends within the text
      " recover linenr and remove leading previous linenr leftover
      let text = linenr . text[ col1 - 1 :]
    endif
    " let text = linenr . text[ [col1, col2, strlen(linenr)] :]
    call setline(line1, text)
  endif

  call b:esearch.undotree.synchronize()
endfu
