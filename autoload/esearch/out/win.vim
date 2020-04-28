let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()
let s:Filepath = vital#esearch#import('System.Filepath')

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

let g:esearch#out#win#searches_with_stopped_highlights = esearch#cache#expiring#new({'max_age': 120, 'size': 1024})

fu! esearch#out#win#init(esearch) abort
  call a:esearch.win_new(a:esearch)
  call esearch#util#doautocmd('User esearch_win_init_pre')
  call s:cleanup()

  let b:esearch = extend(a:esearch, {
        \ 'bufnr':              bufnr('%'),
        \ 'mode':               'normal',
        \ 'reload':             function('<SID>reload'),
        \ 'highlights_enabled': g:esearch.win_contexts_syntax,
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

  " Prevent from blinking on reloads if the command is known to have a large
  " output
  if g:esearch#out#win#searches_with_stopped_highlights.has(b:esearch.request.command)
    let b:esearch.highlights_enabled = 0
    if g:esearch.win_matches_highlight_strategy ==# 'viewport'
      call esearch#out#win#appearance#matches#init(b:esearch)
    endif
  else
    " Highlights should be set after setting the filetype as all the definitions
    " are inside syntax/esearch.vim
    call esearch#out#win#appearance#matches#init(b:esearch)
    if g:esearch.win_contexts_syntax
      call esearch#out#win#appearance#ctx_syntax#init(b:esearch)
    endif
    if g:esearch.win_cursor_linenr_highlight
      call esearch#out#win#appearance#cursor_linenr#init(b:esearch)
    endif
  endif
  if g:esearch.win_ui_nvim_syntax
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
  call esearch#out#win#appearance#ctx_syntax#apply_to_viewport_without_margins(b:esearch)
endfu

fu! s:cleanup() abort
  if exists('b:esearch')
    call esearch#backend#{b:esearch.backend}#abort(b:esearch.bufnr)
    call esearch#out#win#modifiable#uninit(b:esearch)
    call esearch#out#win#update#uninit(b:esearch)
    call esearch#out#win#appearance#matches#uninit(b:esearch)
    call esearch#out#win#appearance#ctx_syntax#uninit(b:esearch)
    call esearch#out#win#appearance#cursor_linenr#uninit(b:esearch)
    call esearch#out#win#appearance#annotations#uninit(b:esearch)
  endif
  aug esearch_win_event
    au! * <buffer>
  aug END
  call esearch#util#doautocmd('User esearch_win_uninit_post')
endfu

fu! esearch#out#win#goto_or_open(esearch) abort dict
  " scope search windows to self.cwd instead of getcwd()
  let safe_slash = g:esearch#has#unicode ? g:esearch#unicode#slash : '{slash}'
  let bufname = substitute(a:esearch.title, '/', safe_slash, 'g')
  let bufname = s:Filepath.join(a:esearch.cwd, bufname)

  " If the window is empty and the only within the tab - reuse it
  if winnr('$') == 1
        \ && empty(&filetype)
        \ && empty(&buftype)
        \ && empty(bufname('%'))
        \ && !&modified
    call esearch#buf#open(bufname, 'edit')
    return
  endif

  call esearch#buf#goto_or_open(bufname, 'tabnew')
endfu

fu! esearch#out#win#stop_highlights(reason) abort
  if g:esearch.win_contexts_syntax || g:esearch.win_matches_highlight_strategy !=# 'viewport'
    echomsg 'esearch: some highlights are disabled to prevent slowdowns (reason: ' . a:reason . ')'
  endif

  call esearch#out#win#appearance#cursor_linenr#soft_stop(b:esearch)
  call esearch#out#win#appearance#ctx_syntax#soft_stop(b:esearch)
  if g:esearch.win_matches_highlight_strategy !=# 'viewport'
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
