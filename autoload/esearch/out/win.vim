let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()
let s:Filepath = vital#esearch#import('System.Filepath')
let s:Buffer   = vital#esearch#import('Vim.Buffer')

" TODO notify c-n and c-p are not used anymore
let g:esearch#out#win#mappings = [
      \ {'lhs': 't',       'rhs': 'tab',                'default': 1},
      \ {'lhs': 'T',       'rhs': 'tab-silent',         'default': 1},
      \ {'lhs': 'o',       'rhs': 'split',              'default': 1},
      \ {'lhs': 'O',       'rhs': 'split-once-silent',  'default': 1},
      \ {'lhs': 's',       'rhs': 'vsplit',             'default': 1},
      \ {'lhs': 'S',       'rhs': 'vsplit-once-silent', 'default': 1},
      \ {'lhs': 'R',       'rhs': 'reload',             'default': 1},
      \ {'lhs': '<Enter>', 'rhs': 'open',               'default': 1},
      \ {'lhs': 'J',       'rhs': 'next',               'default': 1},
      \ {'lhs': 'K',       'rhs': 'prev',               'default': 1},
      \ {'lhs': '}',       'rhs': 'next-file',          'default': 1},
      \ {'lhs': '{',       'rhs': 'prev-file',          'default': 1},
      \ ]

let g:esearch#out#win#entry_pattern = '^\s\+\d\+\s\+.*'
let g:esearch#out#win#filename_pattern = '^[^ ]' " '\%>2l'
let g:esearch#out#win#result_text_regex_prefix = '\%>1l\%(\s\+\d\+\s.*\)\@<='
let g:esearch#out#win#linenr_format = ' %3d '
let g:esearch#out#win#entry_format = ' %3d %s'

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
  let g:esearch_win_results_len_annotations = g:esearch#has#virtual_text
endif

let g:esearch#out#win#searches_with_stopped_highlights = esearch#cache#expiring#new({'max_age': 120, 'size': 1024})

fu! esearch#out#win#init(esearch) abort
  call s:find_or_create_buf(a:esearch, g:esearch#out#win#open)
  call esearch#util#doautocmd('User esearch_win_init_pre')
  call s:cleanup()

  let b:esearch = extend(a:esearch, {
        \ 'bufnr':              bufnr('%'),
        \ 'mode':               'normal',
        \ 'reload':             function('<SID>reload'),
        \ 'highlights_enabled': g:esearch#out#win#context_syntax_highlight,
        \})

  call esearch#out#win#open#init(b:esearch)
  call esearch#out#win#preview#floating#init(b:esearch)
  call esearch#out#win#preview#split#init(b:esearch)
  call esearch#out#win#header#init(b:esearch)
  call esearch#out#win#view_data#init(b:esearch)
  call esearch#out#win#jumps#init(b:esearch)
  call esearch#out#win#render#init(b:esearch)
  call esearch#out#win#update#init(b:esearch)

  " Some plugins set mappings on filetype, so they should be set after.
  " Other things can be conveniently redefined using au FileType esearch
  call s:init_mappings()
  call s:init_commands()

  call extend(b:esearch.request, {
        \ 'bufnr':      bufnr('%'),
        \})

  setl filetype=esearch

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
    call luaeval('esearch.appearance.highlight_header(true)')
  endif

  aug esearch_win_event
    call esearch#util#doautocmd('User esearch_win_event')
  aug END
  call esearch#util#doautocmd('User esearch_win_init_post')

  if esearch#out#win#update#can_finish_early(b:esearch)
    call esearch#out#win#update#finish(bufnr('%'))
  endif
  " If there are any results ready and if the traits are initialized - try
  " to add the highlights prematurely without waiting for debouncing callback
  " firing. Premature highlights are more lightweight as they highlight
  " only the visiable part of viewport without it's margins (they will be
  " highlighted later using debounced callbacks).
  call esearch#out#win#appearance#matches#apply_to_viewport_without_margins(b:esearch)
  call esearch#out#win#appearance#ctx_syntaxes#apply_to_viewport_without_margins(b:esearch)
endfu

fu! s:cleanup() abort
  if exists('b:esearch')
    call esearch#backend#{b:esearch.backend}#abort(b:esearch.bufnr)
    call esearch#out#win#modifiable#uninit(b:esearch)
    call esearch#out#win#update#uninit(b:esearch)
    call esearch#out#win#appearance#matches#uninit(b:esearch)
    call esearch#out#win#appearance#ctx_syntaxes#uninit(b:esearch)
    call esearch#out#win#appearance#cursor_linenr#uninit(b:esearch)
    call esearch#out#win#appearance#annotations#uninit(b:esearch)
  endif
  aug esearch_win_event
    au! * <buffer>
  aug END
  call esearch#util#doautocmd('User esearch_win_uninit_post')
endfu

" TODO customizability
fu! s:find_or_create_buf(esearch, opener) abort
  let escaped = a:esearch.title

  let safe_slash = g:esearch#has#unicode ? g:esearch#unicode#slash : '{slash}'
  let escaped = substitute(escaped, '/', safe_slash, 'g')
  let escaped = substitute(escaped, '\n', '\\n', 'g') " for vital's .open()
  let escaped = substitute(escaped, '\r', '\\r', 'g') " for vital's .open()
  " scope search windows to search cwd instead of global cwd
  let escaped = s:Filepath.join(a:esearch.cwd, escaped)

  let bufnr = esearch#buf#find(escaped)
  " Noop if the buffer is current
  if bufnr == bufnr('%') | return | endif
  " Open if doesn't exist
  if bufnr == -1
    silent return s:Buffer.open(escaped, {'opener': a:opener})
  endif
  let [tabnr, winnr] = esearch#buf#location(bufnr)
  " Open if closed
  if empty(winnr)
    silent return s:Buffer.open(escaped, {'opener': a:opener})
  endif
  " Locate if opened
  silent exe 'tabnext ' . tabnr
  exe winnr . 'wincmd w'
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
  call esearch#mapping#add(g:esearch#out#win#mappings, a:lhs, a:rhs)
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
  nnoremap <silent><buffer> <Plug>(esearch-win-reload)             :<C-U>cal b:esearch.reload()<CR>

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
endfu

fu! s:reload() abort dict
  call esearch#backend#{self.backend}#abort(self.bufnr)
  let self.contexts = []
  let self.ctx_ids_map = []
  let self.ctx_by_name = {}
  let self.undotree = {}
  return esearch#init(self)
endfu

fu! s:invoke_mapping_callback(i) abort
  call g:esearch#out#win#mappings[a:i].rhs(b:esearch)
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
