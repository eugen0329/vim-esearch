let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()
let s:Filepath = vital#esearch#import('System.Filepath')

let g:esearch#out#win#legacy_mappings = {
      \ 'open':               '<Plug>(esearch-win-open)',
      \ 'tab':                '<Plug>(esearch-win-tabopen)',
      \ 'tab-silent':         '<Plug>(esearch-win-tabopen:stay)',
      \ 'split':              '<Plug>(esearch-win-split)',
      \ 'split-once-silent':  '<Plug>(esearch-win-split:reuse:stay)',
      \ 'vsplit':             '<Plug>(esearch-win-vsplit)',
      \ 'vsplit-once-silent': '<Plug>(esearch-win-vsplit:reuse:stay)',
      \ 'reload':             '<Plug>(esearch-win-reload)',
      \ 'next':               '<Plug>(esearch-win-jump:entry:down)',
      \ 'prev':               '<Plug>(esearch-win-jump:entry:up)',
      \ 'next-file':          '<Plug>(esearch-win-jump:filename:down)',
      \ 'prev-file':          '<Plug>(esearch-win-jump:filename:up)',
      \}

let g:esearch#out#win#entry_re = '^\s\+\d\+\s\+.*'
let g:esearch#out#win#filename_re = '^[^ ]'
let g:esearch#out#win#result_text_regex_prefix_re = '\%>1l\%(\s\+\d\+\s.*\)\@<='
let g:esearch#out#win#linenr_format = ' %3d '
let g:esearch#out#win#entry_format = ' %3d %s'

let g:esearch#out#win#searches_with_stopped_highlights = esearch#cache#expiring#new({'max_age': 120, 'size': 1024})

fu! esearch#out#win#init(esearch) abort
  if esearch#util#is_skip_exec(a:esearch) | return s:init_live_updated(a:esearch) | endif

  if get(a:esearch, 'bufnr') !=# bufnr('') | call a:esearch.win_new(a:esearch) | endif
  let clean = s:cleanup()
  call esearch#util#doautocmd('User esearch_win_init_pre')

  let b:esearch = extend(a:esearch, {
        \ 'bufnr':           bufnr('%'),
        \ 'mode':            'normal',
        \ 'reload':          function('<SID>reload'),
        \ 'slow_hl_enabled': a:esearch.win_contexts_syntax || a:esearch.win_cursor_linenr_highlight,
        \})

  call esearch#out#win#open#init(b:esearch)
  call esearch#out#win#preview#floating#init(b:esearch)
  call esearch#out#win#preview#split#init(b:esearch)
  call esearch#out#win#header#init(b:esearch)
  call esearch#out#win#view_data#init(b:esearch)
  call esearch#out#win#jumps#init(b:esearch)
  call esearch#out#win#update#init(b:esearch)
  call esearch#out#win#textobj#init(b:esearch)

  " Some plugins set mappings on filetype, so they should be set after.
  " Other things can be conveniently redefined using au FileType esearch
  if clean | call s:init_mappings() | endif

  setfiletype esearch

  " Prevent from blinking on reloads if the command is known to have a large
  " output
  if g:esearch#out#win#searches_with_stopped_highlights.has(b:esearch.request.command)
    let b:esearch.slow_hl_enabled = 0
    if g:esearch.win_matches_highlight_strategy ==# 'viewport'
      call esearch#out#win#appearance#matches#init(b:esearch)
    endif
  else
    " Highlights should be set after setting the filetype as all the definitions
    " are inside syntax/esearch.vim
    call esearch#out#win#appearance#matches#init(b:esearch)
    call esearch#out#win#appearance#ctx_syntax#init(b:esearch)
    call esearch#out#win#appearance#cursor_linenr#init(b:esearch)
  endif
  if g:esearch.win_ui_nvim_syntax
    call luaeval('esearch.appearance.highlight_header(true)')
  endif

  aug esearch_win_config
    call esearch#util#doautocmd('User esearch_win_config')
  aug END
  call esearch#util#doautocmd('User esearch_win_init_post')

  if esearch#out#win#update#can_finish_early(b:esearch)
    call esearch#out#win#update#finish(bufnr('%'))
  endif
  " If there are any results ready - try to add the highlights prematurely
  " without waiting for debouncing callback firing.
  call esearch#out#win#appearance#matches#hl_viewport(b:esearch)
  call esearch#out#win#appearance#ctx_syntax#hl_viewport(b:esearch)
  return b:esearch
endfu

fu! s:init_live_updated(esearch) abort
  let bufname = s:Filepath.join(a:esearch.cwd, a:esearch.name)
  try
    call esearch#buf#rename(s:Filepath.join(a:esearch.cwd, a:esearch.name))
    call esearch#util#doautocmd('BufEnter')
  catch /E95:/ " Buffer with this name already exists
    let bufnr = bufnr('')
    call a:esearch.win_new(a:esearch)
    if bufnr !=# bufnr('') | exe bufnr 'bwipeout' | endif
  endtry
  return a:esearch
endfu

fu! s:cleanup() abort
  call esearch#util#doautocmd('User esearch_win_uninit_pre')
  if exists('b:esearch')
    call esearch#backend#{b:esearch.backend}#abort(b:esearch.bufnr)
    call esearch#out#win#modifiable#uninit(b:esearch)
    call esearch#out#win#update#uninit(b:esearch)
    call esearch#out#win#appearance#matches#uninit(b:esearch)
    call esearch#out#win#appearance#ctx_syntax#uninit(b:esearch)
    call esearch#out#win#appearance#cursor_linenr#uninit(b:esearch)
    call esearch#out#win#appearance#annotations#uninit(b:esearch)
  endif
  aug esearch_win_config
    au! * <buffer>
  aug END
  return !exists('b:esearch')
endfu

fu! esearch#out#win#goto_or_open(esearch) abort dict
  let bufname = s:Filepath.join(a:esearch.cwd, a:esearch.name)

  " If the window is empty and the only within the tab - reuse it
  if winnr('$') == 1
        \ && empty(&filetype)
        \ && empty(&buftype)
        \ && empty(bufname('%'))
        \ && !&modified
    silent call esearch#buf#open(bufname, 'noswap edit')
    return
  endif

  silent call esearch#buf#goto_or_open(bufname, 'noswap tabnew')
endfu

fu! esearch#out#win#stop_highlights(reason) abort
  if g:esearch.win_contexts_syntax || g:esearch.win_matches_highlight_strategy !=# 'viewport'
    call esearch#util#warn('esearch: some highlights are disabled to prevent slowdowns (reason: ' . a:reason . ')')
  endif

  call esearch#out#win#appearance#cursor_linenr#soft_stop(b:esearch)
  call esearch#out#win#appearance#ctx_syntax#soft_stop(b:esearch)
  if g:esearch.win_matches_highlight_strategy !=# 'viewport'
    call esearch#out#win#appearance#matches#soft_stop(b:esearch)
  endif
  call g:esearch#out#win#searches_with_stopped_highlights.set(b:esearch.request.command, 1)
endfu

fu! esearch#out#win#map(lhs, rhs) abort
  let g:esearch = get(g:, 'esearch', {})
  let g:esearch = extend(g:esearch, {'win_map': []}, 'keep')
  let g:esearch = extend(g:esearch, {'pending_warnings': []}, 'keep')
  let esearch#util#deprecate('esearch#out#win#map, see :help g:esearch.win_map')
  let g:esearch.win_map += [{'lhs': a:lhs, 'rhs': get(g:esearch#out#win#legacy_mappings, a:rhs, a:rhs), 'mode': 'n'}]
endfu

fu! s:init_mappings() abort
  nnoremap <silent><buffer> <Plug>(esearch-win-reload)            :<C-U>cal b:esearch.reload()<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-open)              :<C-U>cal b:esearch.open('edit')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-tabopen)           :<C-U>cal b:esearch.open('tabnew')<cr>
  nnoremap <silent><buffer> <Plug>(esearch-win-tabopen:stay)      :<C-U>cal b:esearch.open('tabnew', {'stay': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split)             :<C-U>cal b:esearch.open('new')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split:stay)        :<C-U>cal b:esearch.open('new', {'stay': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split:reuse)       :<C-U>cal b:esearch.open('new', {'reuse': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-split:reuse:stay)  :<C-U>cal b:esearch.open('new', {'stay': 1, 'reuse': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit)            :<C-U>cal b:esearch.open('vnew')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit:stay)       :<C-U>cal b:esearch.open('vnew', {'stay': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit:reuse)      :<C-U>cal b:esearch.open('vnew', {'reuse': 1})<CR>
  nnoremap <silent><buffer> <Plug>(esearch-win-vsplit:reuse:stay) :<C-U>cal b:esearch.open('vnew', {'stay': 1, 'reuse': 1})<CR>
  if g:esearch#has#preview
    nnoremap <silent><buffer> <Plug>(esearch-win-preview)         :<C-U>cal b:esearch.preview_zoom()<CR>
    nnoremap <silent><buffer> <Plug>(esearch-win-preview:enter)   :<C-U>cal b:esearch.preview_enter()<CR>
  else
    nnoremap <silent><buffer> <Plug>(esearch-win-preview)         :<C-U>cal b:esearch.split_preview_open('vnew')<CR>
    nnoremap <silent><buffer> <Plug>(esearch-win-preview:enter)   :<C-U>cal b:esearch.split_preview_open('vnew', {'stay': 0})<CR>
  endif

  noremap  <silent><buffer> <Plug>(esearch-win-jump:filename:up)   :<C-U>cal b:esearch.jump2filename(-1, v:count1)<CR>
  noremap  <silent><buffer> <Plug>(esearch-win-jump:filename:down) :<C-U>cal b:esearch.jump2filename(1, v:count1)<CR>
  vnoremap <silent><buffer> <Plug>(esearch-win-jump:filename:up)   :<C-U>cal b:esearch.jump2filename(-1, v:count1, 'v')<CR>
  vnoremap <silent><buffer> <Plug>(esearch-win-jump:filename:down) :<C-U>cal b:esearch.jump2filename(1, v:count1, 'v')<CR>

  noremap  <silent><buffer> <Plug>(esearch-win-jump:entry:up)      :<C-U>cal b:esearch.jump2entry(-1, v:count1)<CR>
  noremap  <silent><buffer> <Plug>(esearch-win-jump:entry:down)    :<C-U>cal b:esearch.jump2entry(1, v:count1)<CR>
  vnoremap <silent><buffer> <Plug>(esearch-win-jump:entry:up)      :<C-U>cal b:esearch.jump2entry(-1, v:count1, 'v')<CR>
  vnoremap <silent><buffer> <Plug>(esearch-win-jump:entry:down)    :<C-U>cal b:esearch.jump2entry(1, v:count1, 'v')<CR>

  vnoremap <silent><buffer> <Plug>(textobj-esearch-match-i) :<C-U>cal esearch#out#win#textobj#match_i(v:count1)<CR>
  onoremap <silent><buffer> <Plug>(textobj-esearch-match-i) :<C-U>cal esearch#out#win#textobj#match_i(v:count1)<CR>
  vnoremap <silent><buffer> <Plug>(textobj-esearch-match-a) :<C-U>cal esearch#out#win#textobj#match_a(v:count1)<CR>
  onoremap <silent><buffer> <Plug>(textobj-esearch-match-a) :<C-U>cal esearch#out#win#textobj#match_a(v:count1)<CR>

  cnoremap <silent><buffer> <Plug>(esearch-win-CR) <C-\>eesearch#out#win#modifiable#cmdline#replace()<CR><CR>

  for args in b:esearch.win_map
    let opts = extend({'buffer': 1, 'silent': 1}, get(args, 3, {}))
    call esearch#keymap#set(args[0], args[1], args[2], opts)
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
