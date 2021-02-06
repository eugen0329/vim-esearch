let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()
let s:Filepath = vital#esearch#import('System.Filepath')

let g:esearch#out#win#legacy_keymaps = {
      \ 'open':               '<plug>(esearch-win-open)',
      \ 'tab':                '<plug>(esearch-win-tabopen)',
      \ 'tab-silent':         '<plug>(esearch-win-tabopen:stay)',
      \ 'split':              '<plug>(esearch-win-split)',
      \ 'split-once-silent':  '<plug>(esearch-win-split:reuse:stay)',
      \ 'vsplit':             '<plug>(esearch-win-vsplit)',
      \ 'vsplit-once-silent': '<plug>(esearch-win-vsplit:reuse:stay)',
      \ 'reload':             '<plug>(esearch-win-reload)',
      \ 'next':               '<plug>(esearch-win-jump:entry:down)',
      \ 'prev':               '<plug>(esearch-win-jump:entry:up)',
      \ 'next-file':          '<plug>(esearch-win-jump:filename:down)',
      \ 'prev-file':          '<plug>(esearch-win-jump:filename:up)',
      \}

let g:esearch#out#win#column_re                = '^\s\+[+^_]\=\s*\d\+\s'
let g:esearch#out#win#entry_re                 = '^\s\+[+^_]\=\s*\d\+\s\+.*'
let g:esearch#out#win#capture_sign_re          = '^\s\+\zs^\ze'
let g:esearch#out#win#capture_lnum_re          = '^\s\+[+^_]\=\s*\zs\d\+\ze.*'
let g:esearch#out#win#capture_entry_re         = '^\s\+\([+^_]\)\=\s*\(\d\+\)\s\(.*\)'
let g:esearch#out#win#capture_sign_and_lnum_re = '^\s\+\([+^_]\)\=\s*\(\d\+\)'
let g:esearch#out#win#ignore_ui_re             = '\%(^\s[+^_]\=\s*\d\+\s.*\)\@<='
let g:esearch#out#win#no_ignore_ui_re          = '\%(^\s[+^_]\=\s*\d\+\s.*\)\@!'
let g:esearch#out#win#nomagic_ignore_ui_re     = '\%(^\s\[+^_]\=\s\*\d\+\s\.\*\)\@<='
let g:esearch#out#win#ignore_ui_hat_re         = '\%(^\s[+^_]\=\s*\d\+\s\)\@<='
let g:esearch#out#win#filename_re = '^[^ ]'
let g:esearch#out#win#separator_re = '^$'
let g:esearch#out#win#linenr_fmt  = ' %3d '
let g:esearch#out#win#entry_fmt   = ' %3d %s'

let g:esearch#out#win#searches_with_stopped_highlights = esearch#cache#expiring#new({'max_age': 120, 'size': 1024})

aug esearch_win_performance
  au!
  " Prevent freezes caused by highlighting long lines
  au User esearch_win_live_update_pre  let b:original_synmaxcol = esearch#let#restorable({'&synmaxcol': &columns})
  au User esearch_win_live_update_post call b:original_synmaxcol.restore() | unlet b:original_synmaxcol
aug END

fu! esearch#out#win#init(esearch) abort
  " If the final live update, do only minor initializations of the already prepared window
  if a:esearch.live_update && !a:esearch.force_exec | return s:live_update_post(a:esearch) | endif

  " Open the window if not focused
  if a:esearch.live_update_bufnr !=# bufnr('') && a:esearch.bufnr !=# bufnr('')
    call a:esearch.win_new(a:esearch)
    if a:esearch.live_update | call esearch#util#doautocmd('User esearch_win_live_update_pre') | endif
  endif

  let was_clean = s:cleanup_old_request(a:esearch)
  call esearch#util#doautocmd('User esearch_win_init_pre')

  if !was_clean && has_key(b:esearch, 'view') | let view = remove(b:esearch, 'view') | endif
  let b:esearch = extend(a:esearch, {
        \ 'bufnr':           bufnr('%'),
        \ 'modifiable':      0,
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

  " Some plugins set keymaps on filetype, so they should be set after.
  " Other things can be conveniently redefined using au FileType esearch
  if was_clean | call s:init_keymaps() | endif

  setfiletype esearch

  " Prevent from blinking on reloads if the command is known to have a large
  " output
  if g:esearch#out#win#searches_with_stopped_highlights.has(b:esearch.request.command)
    let b:esearch.slow_hl_enabled = 0
    if g:esearch.win_matches_highlight_strategy is# 'viewport'
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
    call luaeval('esearch.highlight_header(nil, true)')
  endif

  aug esearch_win_config
    call esearch#util#doautocmd('User esearch_win_config')
  aug END
  call esearch#util#doautocmd('User esearch_win_init_post')

  if esearch#out#win#update#can_finish_early(b:esearch)
    call esearch#out#win#update#finish(bufnr('%'))
  endif

  " For some searches there will already be enough lines to restore the view
  " while can_finish_early is executed
  if exists('view') | call s:winrestview(b:esearch, view) | endif

  " If there are any results ready - try to add the highlights prematurely
  " without waiting for debouncing callback firing.
  call esearch#out#win#appearance#matches#hl_viewport(b:esearch)
  if b:esearch.win_contexts_syntax
    call esearch#out#win#appearance#ctx_syntax#hl_viewport(b:esearch)
  endif

  return b:esearch
endfu

fu! s:live_update_post(esearch) abort
  if !exists('b:esearch') | return | endif
  silent! unlet a:esearch.bufnr
  call extend(b:esearch, a:esearch, 'force')
  call extend(b:esearch, {'force_exec': 0, 'live_update_bufnr': -1}, 'force')
  let abspath = esearch#util#abspath(b:esearch.cwd, b:esearch.name)

  try
    call esearch#buf#rename(abspath)
  catch /E95:/ " Buffer with this name already exists
    let bufnr = esearch#buf#find(abspath)
    try
      exe bufnr 'bdelete'
    catch /\(E89\|E516\):/  " When the buf is modified and (&confirm == 0 or cancelled)
      exe b:esearch.bufnr 'bdelete'
      return
    endtry
    call esearch#buf#rename(abspath)
  endtry
  call esearch#out#win#appearance#matches#init_live_updated(b:esearch)
  call esearch#util#doautocmd('WinEnter') " hit statuslines updates
  call esearch#util#doautocmd('User esearch_win_live_update_post')
  return b:esearch
endfu

fu! s:cleanup_old_request(esearch) abort
  call esearch#util#doautocmd('User esearch_win_uninit_pre')
  if exists('b:esearch')
    call esearch#backend#{b:esearch.backend}#abort(b:esearch.bufnr)
    call esearch#out#win#modifiable#uninit(b:esearch)
    call esearch#out#win#update#uninit(b:esearch)
    call esearch#out#win#appearance#matches#uninit(b:esearch)
    call esearch#out#win#appearance#ctx_syntax#uninit(b:esearch)
    call esearch#out#win#appearance#cursor_linenr#uninit(b:esearch)
    call esearch#out#win#appearance#annotations#uninit(b:esearch)
    if !a:esearch.force_exec | let b:esearch.view = s:winsaveview(b:esearch) | endif
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
  if g:esearch.win_contexts_syntax || g:esearch.win_matches_highlight_strategy isnot# 'viewport'
    call esearch#util#warn('esearch: some highlights are disabled to prevent slowdowns (reason: ' . a:reason . ')')
  endif

  call esearch#out#win#appearance#cursor_linenr#soft_stop(b:esearch)
  call esearch#out#win#appearance#ctx_syntax#soft_stop(b:esearch)
  if g:esearch.win_matches_highlight_strategy isnot# 'viewport'
    call esearch#out#win#appearance#matches#soft_stop(b:esearch)
  endif
  silent! syn clear esearchDiffAdd
  call g:esearch#out#win#searches_with_stopped_highlights.set(b:esearch.request.command, 1)
endfu

fu! esearch#out#win#map(lhs, rhs) abort
  let g:esearch = get(g:, 'esearch', {})
  let g:esearch = extend(g:esearch, {'win_map': []}, 'keep')
  let g:esearch = extend(g:esearch, {'pending_warnings': []}, 'keep')
  call esearch#util#deprecate('esearch#out#win#map, see :help g:esearch.win_map')
  let g:esearch.win_map += [['n', a:lhs, get(g:esearch#out#win#legacy_keymaps, a:rhs, a:rhs)]]
endfu

fu! s:init_keymaps() abort
  nnoremap <silent><buffer><plug>(esearch-win-reload)            :<c-u>cal b:esearch.reload()<cr>
  nnoremap <silent><buffer><plug>(esearch-win-open)              :<c-u>cal b:esearch.open('edit')<cr>
  nnoremap <silent><buffer><plug>(esearch-win-tabopen)           :<c-u>cal b:esearch.open('tabnew')<cr>
  nnoremap <silent><buffer><plug>(esearch-win-tabopen:stay)      :<c-u>cal b:esearch.open('tabnew', {'stay': 1})<cr>
  nnoremap <silent><buffer><plug>(esearch-win-split)             :<c-u>cal b:esearch.open('new')<cr>
  nnoremap <silent><buffer><plug>(esearch-win-split:stay)        :<c-u>cal b:esearch.open('new', {'stay': 1})<cr>
  nnoremap <silent><buffer><plug>(esearch-win-split:reuse)       :<c-u>cal b:esearch.open('new', {'reuse': 1})<cr>
  nnoremap <silent><buffer><plug>(esearch-win-split:reuse:stay)  :<c-u>cal b:esearch.open('new', {'stay': 1, 'reuse': 1})<cr>
  nnoremap <silent><buffer><plug>(esearch-win-vsplit)            :<c-u>cal b:esearch.open('vnew')<cr>
  nnoremap <silent><buffer><plug>(esearch-win-vsplit:stay)       :<c-u>cal b:esearch.open('vnew', {'stay': 1})<cr>
  nnoremap <silent><buffer><plug>(esearch-win-vsplit:reuse)      :<c-u>cal b:esearch.open('vnew', {'reuse': 1})<cr>
  nnoremap <silent><buffer><plug>(esearch-win-vsplit:reuse:stay) :<c-u>cal b:esearch.open('vnew', {'stay': 1, 'reuse': 1})<cr>
  if g:esearch#has#preview
    nnoremap <silent><buffer><plug>(esearch-win-preview)             :<c-u>cal b:esearch.preview_zoom(v:count1, {'close_on': g:esearch#preview#close_on_move})<cr>
    nnoremap <silent><buffer><plug>(esearch-win-preview:enter)       :<c-u>cal b:esearch.preview_enter(v:count1)<cr>
    nnoremap <expr><silent><buffer><plug>(esearch-win-preview:close) b:esearch.preview_close() ? '' : "\<esc>"
  else
    nnoremap <silent><buffer><plug>(esearch-win-preview)         :<c-u>cal b:esearch.split_preview_open('vnew')<cr>
    nnoremap <silent><buffer><plug>(esearch-win-preview:enter)   :<c-u>cal b:esearch.split_preview_open('vnew', {'stay': 0})<cr>
  endif
  noremap  <silent><buffer><plug>(esearch-win-jump:filename:up)   :<c-u>cal b:esearch.jump2filename(-v:count1)<cr>
  noremap  <silent><buffer><plug>(esearch-win-jump:filename:down) :<c-u>cal b:esearch.jump2filename(v:count1)<cr>
  vnoremap <silent><buffer><plug>(esearch-win-jump:filename:up)   :<c-u>cal b:esearch.jump2filename(-v:count1, 'v')<cr>
  vnoremap <silent><buffer><plug>(esearch-win-jump:filename:down) :<c-u>cal b:esearch.jump2filename(v:count1, 'v')<cr>
  noremap  <silent><buffer><plug>(esearch-win-jump:dirname:up)    :<c-u>cal b:esearch.jump2dirname(-v:count1)<cr>
  noremap  <silent><buffer><plug>(esearch-win-jump:dirname:down)  :<c-u>cal b:esearch.jump2dirname(v:count1)<cr>
  vnoremap <silent><buffer><plug>(esearch-win-jump:dirname:up)    :<c-u>cal b:esearch.jump2dirname(-v:count1, 'v')<cr>
  vnoremap <silent><buffer><plug>(esearch-win-jump:dirname:down)  :<c-u>cal b:esearch.jump2dirname(v:count1, 'v')<cr>
  noremap  <silent><buffer><plug>(esearch-win-jump:entry:up)      :<c-u>cal b:esearch.jump2entry(-v:count1)<cr>
  noremap  <silent><buffer><plug>(esearch-win-jump:entry:down)    :<c-u>cal b:esearch.jump2entry(v:count1)<cr>
  vnoremap <silent><buffer><plug>(esearch-win-jump:entry:up)      :<c-u>cal b:esearch.jump2entry(-v:count1, 'v')<cr>
  vnoremap <silent><buffer><plug>(esearch-win-jump:entry:down)    :<c-u>cal b:esearch.jump2entry(v:count1, 'v')<cr>
  vnoremap <silent><buffer><plug>(textobj-esearch-match-i) :<c-u>cal esearch#out#win#textobj#match_i(1, v:count1)<cr>
  onoremap <silent><buffer><plug>(textobj-esearch-match-i) :<c-u>cal esearch#out#win#textobj#match_i(0, v:count1)<cr>
  vnoremap <silent><buffer><plug>(textobj-esearch-match-a) :<c-u>cal esearch#out#win#textobj#match_a(1, v:count1)<cr>
  onoremap <silent><buffer><plug>(textobj-esearch-match-a) :<c-u>cal esearch#out#win#textobj#match_a(0, v:count1)<cr>

  cnoremap       <silent><buffer><plug>(esearch-cr) <c-\>eesearch#out#win#modifiable#cmdline#replace(getcmdline(), getcmdtype())<cr><cr>
  inoremap <expr><silent><buffer><plug>(esearch-cr) esearch#out#win#modifiable#cr()
  nnoremap <expr><silent><buffer><plug>(esearch-I)  esearch#out#win#modifiable#I()
  noremap  <expr><silent><buffer><plug>(esearch-d)  esearch#operator#expr('esearch#out#win#modifiable#d')
  noremap  <expr><silent><buffer><plug>(esearch-dd) esearch#operator#expr('esearch#out#win#modifiable#d').'g@'
  noremap  <expr><silent><buffer><plug>(esearch-d.) esearch#operator#expr('esearch#out#win#modifiable#d_dot')
  nnoremap <expr><silent><buffer><plug>(esearch-D)  col('$')==1 ? '' : (col('.')==col('$')?'$':'').esearch#operator#expr('esearch#out#win#modifiable#d').'$'
  xnoremap <expr><silent><buffer><plug>(esearch-D)  'V'.esearch#operator#expr('esearch#out#win#modifiable#d')
  noremap  <expr><silent><buffer><plug>(esearch-c)  esearch#out#win#modifiable#seq().esearch#operator#expr('esearch#out#win#modifiable#c')
  noremap  <expr><silent><buffer><plug>(esearch-cc) esearch#out#win#modifiable#seq("g@").esearch#operator#expr('esearch#out#win#modifiable#c').'g@'
  noremap  <expr><silent><buffer><plug>(esearch-c.) esearch#operator#expr('esearch#out#win#modifiable#c_dot')
  nnoremap <expr><silent><buffer><plug>(esearch-C)  col('$')==1 ? 'i' : (col('.')==col('$')?'$':'').esearch#out#win#modifiable#seq('$').esearch#operator#expr('esearch#out#win#modifiable#c').'$'
  xnoremap <expr><silent><buffer><plug>(esearch-C)  'V'.esearch#operator#expr('esearch#out#win#modifiable#c')
  nnoremap       <silent><buffer><plug>(esearch-.)  :<c-u>exe esearch#repeat#run(v:count)<cr>
  nnoremap       <silent><buffer><plug>(esearch-@:) :<c-u>exe esearch#out#win#modifiable#cmdline#repeat(v:count1)<cr>

  nnoremap <expr><silent><buffer><plug>(esearch-za) foldclosed(line('.')) == -1 ? (foldlevel(line('.')) > 0 ? 'zD' : '').esearch#out#win#fold#close() : (foldlevel(line('.')) > 0 ? 'zO' : '')
  nnoremap <expr><silent><buffer><plug>(esearch-zc) (foldlevel(line('.')) > 0 ? 'zD' : '').esearch#out#win#fold#close()
  nnoremap       <silent><buffer><plug>(esearch-zM) :call esearch#out#win#fold#close_all()<cr>

  call esearch#out#win#init_user_keymaps()
endfu

fu! esearch#out#win#init_user_keymaps() abort
  for args in b:esearch.win_map
    let opts = extend({'buffer': 1, 'silent': 1}, get(args, 3, {}))
    call esearch#keymap#set(args[0], args[1], args[2], opts)
  endfor
endfu

fu! esearch#out#win#uninit_user_keymaps() abort
  for args in b:esearch.win_map
    let opts = extend({'buffer': 1, 'silent': 1}, get(args, 3, {}))
    silent! call esearch#keymap#del(args[0], args[1], opts)
  endfor
endfu

fu! s:reload(...) abort dict
  if &modified && confirm('The window is modified. Reload?', "&Yes\n&Cancel") == 2
    return
  endif
  call esearch#backend#{self.backend}#abort(self.bufnr)
  let self.live_update = 0
  return esearch#init(extend(self, get(a:, 1, {})))
endfu

" Bind view to a line within a context.
fu! s:winsaveview(esearch) abort
  let view = winsaveview()
  let view.ctx_lnum = matchstr(getline('.'), g:esearch#out#win#capture_lnum_re)
  let state = a:esearch.state
  let id = get(state, view.lnum)
  if id | let view.filename = a:esearch.contexts[state[view.lnum]].filename | endif
  return view
endfu

fu! s:winrestview(esearch, view) abort
  if has_key(a:view, 'filename')
    let ctx = get(a:esearch.ctx_by_name, remove(a:view, 'filename'), 0)
    if empty(ctx) | return winrestview(a:view) | endif

    let offset = index(sort(keys(ctx.lines), 'N'), remove(a:view, 'ctx_lnum'))
    let lnum = ctx.begin + offset + 1
    let a:view.topline += lnum - a:view.lnum
    let a:view.lnum = lnum
  endif
  call winrestview(a:view)
endfu
