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

let s:Vital   = vital#esearch#new()
let s:Promise = s:Vital.import('Async.Promise')
let s:List    = s:Vital.import('Data.List')
let s:String  = s:Vital.import('Data.String')
let s:Filepath = s:Vital.import('System.Filepath')

let s:mappings = [
      \ {'lhs': 't',       'rhs': '<Plug>(esearch-win-tab)', 'default': 1},
      \ {'lhs': 'T',       'rhs': '<Plug>(esearch-win-tab-silent)', 'default': 1},
      \ {'lhs': 'o',       'rhs': '<Plug>(esearch-win-split)', 'default': 1},
      \ {'lhs': 'O',       'rhs': '<Plug>(esearch-win-split-silent)', 'default': 1},
      \ {'lhs': 's',       'rhs': '<Plug>(esearch-win-vsplit)', 'default': 1},
      \ {'lhs': 'S',       'rhs': '<Plug>(esearch-win-vsplit-silent)', 'default': 1},
      \ {'lhs': 'R',       'rhs': '<Plug>(esearch-win-reload)', 'default': 1},
      \ {'lhs': '<Enter>', 'rhs': '<Plug>(esearch-win-open)', 'default': 1},
      \ {'lhs': '<C-n>',   'rhs': '<Plug>(esearch-win-next)', 'default': 1},
      \ {'lhs': '<C-p>',   'rhs': '<Plug>(esearch-win-prev)', 'default': 1},
      \ {'lhs': '<S-j>',   'rhs': '<Plug>(esearch-win-next-file)', 'default': 1},
      \ {'lhs': '<S-k>',   'rhs': '<Plug>(esearch-win-prev-file)', 'default': 1},
      \ ]

let s:null = 0
let s:RESULT_LINE_PATTERN = '^\%>1l\s\+\d\+.*'
" The first line. It contains information about the number of results
let s:file_entry_pattern = '^\s\+\d\+\s\+.*'
let s:filename_pattern = '^[^ ]' " '\%>2l'
let s:lines_map_padding = 0 " to index with line numbers which begin from 1
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
let g:esearch#out#win#result_text_regex_prefix = '\%>1l\%(\s\+\d\+\s.*\)\@<='
let s:linenr_format = ' %3d %s'

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
        \ (g:esearch#has#nvim_add_highlight && g:esearch#has#nvim_lua ? 'viewport' : 'matchadd')
endif
if !exists('g:esearch_win_disable_context_highlights_on_files_count')
  let g:esearch_win_disable_context_highlights_on_files_count =
        \ (g:esearch_out_win_highlight_matches ==# 'viewport' ? 2000 : 200)
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
        \ g:esearch#has#virtual_cursor_linenr_highlight && &cursorline
endif
if !exists('g:esearch_out_win_render_using_lua')
  let g:esearch_out_win_render_using_lua = g:esearch#has#lua
endif
if !exists('g:esearch_out_win_nvim_lua_syntax')
  let g:esearch_out_win_nvim_lua_syntax = g:esearch_out_win_render_using_lua && g:esearch#has#nvim_lua
endif
if !exists('g:unload_context_syntax_on_line_length')
  let g:unload_context_syntax_on_line_length = 500
endif
if !exists('g:unload_global_syntax_on_line_length')
  let g:unload_global_syntax_on_line_length = 30000
endif

let s:context_syntaxes = {
      \ 'c':               'es_ctx_c',
      \ 'cpp':             'es_ctx_c',
      \ 'xs':              'es_ctx_c',
      \ 'cmod':            'es_ctx_c',
      \ 'rpcgen':          'es_ctx_c',
      \ 'haskell':         'es_ctx_haskell',
      \ 'lhaskell':        'es_ctx_haskell',
      \ 'agda':            'es_ctx_haskell',
      \ 'sh':              'es_ctx_sh',
      \ 'bash':            'es_ctx_sh',
      \ 'zsh':             'es_ctx_sh',
      \ 'bats':            'es_ctx_sh',
      \ 'javascript':      'es_ctx_javascript',
      \ 'javascriptreact': 'es_ctx_javascriptreact',
      \ 'typescript':      'es_ctx_typescript',
      \ 'typescriptreact': 'es_ctx_typescriptreact',
      \ 'coffee':          'es_ctx_javascript',
      \ 'litcoffee':       'es_ctx_javascript',
      \ 'php':             'es_ctx_php',
      \ 'phtml':           'es_ctx_php',
      \ 'go':              'es_ctx_go',
      \ 'ruby':            'es_ctx_ruby',
      \ 'racc':            'es_ctx_ruby',
      \ 'xml':             'es_ctx_xml',
      \ 'svg':             'es_ctx_xml',
      \ 'ant':             'es_ctx_xml',
      \ 'papp':            'es_ctx_xml',
      \ 'html':            'es_ctx_html',
      \ 'xhtml':           'es_ctx_html',
      \ 'haml':            'es_ctx_html',
      \ 'htmlcheetah':     'es_ctx_html',
      \ 'wml':             'es_ctx_html',
      \ 'jsp':             'es_ctx_html',
      \ 'template':        'es_ctx_html',
      \ 'htmldjango':      'es_ctx_html',
      \ 'htmlm4':          'es_ctx_html',
      \ 'vue':             'es_ctx_html',
      \ 'java':            'es_ctx_java',
      \ 'python':          'es_ctx_python',
      \ 'kivy':            'es_ctx_python',
      \ 'pyrex':           'es_ctx_python',
      \ 'json':            'es_ctx_json',
      \ 'yaml':            'es_ctx_yaml',
      \ 'liquid':          'es_ctx_yaml',
      \ 'toml':            'es_ctx_toml',
      \ 'dockerfile':      'es_ctx_dockerfile',
      \ 'css':             'es_ctx_css',
      \ 'scss':            'es_ctx_css',
      \ 'sass':            'es_ctx_css',
      \ 'less':            'es_ctx_css',
      \ 'hcl':             'es_ctx_hcl',
      \ 'groovy':          'es_ctx_groovy',
      \ 'vim':             'es_ctx_vim',
      \ 'Jenkinsfile':     'es_ctx_groovy',
      \ 'scala':           'es_ctx_scala',
      \ 'lisp':            'es_ctx_lisp',
      \ 'clojure':         'es_ctx_lisp',
      \ 'rust':            'es_ctx_generic',
      \ 'swift':           'es_ctx_generic',
      \ 'elixir':          'es_ctx_generic',
      \ 'erlang':          'es_ctx_generic',
      \ 'fortran':         'es_ctx_generic',
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
  if has_key(b:, 'esearch')
    call s:cleanup()
  end

  setl ft=esearch

  setl modifiable
  exe '1,$d_'
  call esearch#util#setline(bufnr('%'), 1, printf(s:header, 0, '', 0, ''))
  setl undolevels=-1 " Disable undo
  setl nomodifiable
  setl nobackup
  setl noswapfile
  setl nonumber
  setl norelativenumber
  setl nospell
  setl nowrap
  setl synmaxcol=400
  setl nolist " prevent listing traling spaces on blank lines
  setl nomodeline
  let &buflisted = g:esearch#out#win#buflisted
  setl foldcolumn=0
  setl buftype=nofile
  setl bufhidden=hide
  setl foldlevel=2
  setl foldmethod=syntax
  setl foldtext=esearch#out#win#foldtext()
  syntax sync minlines=100

  let b:esearch = extend(a:opts, {
        \ 'bufnr':                    bufnr('%'),
        \ 'last_update_at':           reltime(),
        \ 'files_count':              0,
        \ 'mode':                     'normal',
        \ 'viewport_highlight_timer': -1,
        \ 'match_highlight_timer':    -1,
        \ 'updates_timer':            -1,
        \ 'update_with_timer_start':  0,
        \ 'max_lines_found':          0,
        \ 'ignore_batches':           0,
        \ 'highlight_viewport':       0,
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
        \ 'without':                  function('esearch#util#without'),
        \ 'header_text':              function('s:header_text'),
        \})

  if b:esearch.request.async
    call s:init_update_events(b:esearch)
  endif
  call s:init_mappings()
  call s:init_commands()

  augroup ESearchWinHighlights
    au! * <buffer>
    if g:esearch_out_win_highlight_cursor_line_number
      au CursorMoved,CursorMovedI <buffer> call s:highlight_cursor_line_number()
    endif
    if g:esearch#out#win#context_syntax_highlight
      au CursorMoved <buffer> call s:highlight_viewport()
    endif
  augroup END

  " setup blank context for header
  call esearch#out#win#add_context(b:esearch.contexts, '', 1)
  let header_context = b:esearch.contexts[0]
  let header_context.end = 2
  let b:esearch.ctx_ids_map += [header_context.id, header_context.id]
  let b:esearch.line_numbers_map += [0, 0]

  call esearch#out#win#matches#init_highlight(b:esearch)
  if g:esearch_out_win_nvim_lua_syntax
    call esearch#out#win#render#lua#init_nvim_syntax(b:esearch)
  endif

  call extend(b:esearch.request, {
        \ 'bufnr':       bufnr('%'),
        \ 'cursor':      0,
        \ 'out_finish':  function('esearch#out#win#_is_render_finished')
        \})

  call esearch#backend#{b:esearch.backend}#run(b:esearch.request)

  if !b:esearch.request.async
    call esearch#out#win#finish(bufnr('%'))
  endif
endfu

if has('nvim')
fu! s:highlight_cursor_line_number() abort
  if has_key(b:, 'esearch_linenr_id')
    call nvim_buf_clear_namespace(0, b:esearch_linenr_id, 0, -1)
  else
    let b:esearch_linenr_id = nvim_create_namespace('esearchLineNr')
  endif

  lua << EOF
    local current_line = vim.api.nvim_get_current_line()
    local _, last_column = current_line:find('^%s+%d+%s')
    if last_column ~= nil then
      vim.api.nvim_buf_add_highlight(0, vim.api.nvim_eval('b:esearch_linenr_id'),
        'esearchCursorLineNr', vim.api.nvim_win_get_cursor(0)[1] - 1, 0, last_column)
    end
EOF
endfu
else
fu! s:highlight_cursor_line_number() abort
  if has_key(b:, 'esearch_linenr_id')
    call esearch#util#safe_matchdelete(b:esearch_linenr_id)
  endif
  let b:esearch_linenr_id = matchadd('esearchCursorLineNr',
        \ '^\s\+\d\+\s' . line('.') . 'l', -1)
endfu
endif

fu! s:cleanup() abort
  call esearch#changes#unlisten_for_current_buffer()
  call esearch#backend#{b:esearch.backend}#abort(bufnr('%'))
  if has_key(b:esearch, 'updates_timer')
    call timer_stop(b:esearch.updates_timer)
  endif
  if has_key(b:esearch, 'viewport_highlight_timer')
    call timer_stop(b:esearch.viewport_highlight_timer)
  endif
  augroup ESearchModifiable
    au! * <buffer>
  augroup END
  call esearch#option#reset()
  call esearch#util#safe_matchdelete(
        \ get(b:esearch, 'matches_highlight_id', -1))
endfu

" TODO refactoring
fu! s:init_update_events(esearch) abort
  if g:esearch_win_update_using_timer && exists('*timer_start')
    let a:esearch.update_with_timer_start = 1

    augroup ESearchWinUpdates
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
    augroup END
  else
    let a:esearch.update_with_timer_start = 0

    augroup ESearchWinUpdates
      au! * <buffer>
      call esearch#backend#{a:esearch.backend}#init_events()
    augroup END
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
  augroup ESearchWinUpdates
    for func_name in keys(a:esearch.request.events)
      let a:esearch.request.events[func_name] = s:null
    endfor
  augroup END
  exe printf('au! ESearchWinUpdates * <buffer=%d>', a:esearch.bufnr)
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
  if bufnr == bufnr('%') " if current buffer
    return 0
  elseif bufnr > 0 " if buffer exists
    let buf_loc = esearch#util#bufloc(bufnr)
    if empty(buf_loc)
      silent exe 'bw ' . bufnr
      silent exe join(filter([a:opencmd, 'file '.escaped], '!empty(v:val)'), '|')
    else
      silent exe 'tabn ' . buf_loc[0]
      exe buf_loc[1].'winc w'
    endif
  else " if buffer doesn't exist
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

  let spinner = s:spinner[esearch.tick / s:spinner_slowdown % s:spinner_frames_size]
  if request.finished
    call esearch#util#setline(a:bufnr, 1, printf(s:request_finished_header,
          \ len(esearch.request.data),
          \ esearch.files_count,
          \ spinner
          \ ))
  else
    call esearch#util#setline(a:bufnr, 1, printf(s:header,
          \ len(esearch.request.data),
          \ spinner,
          \ esearch.files_count,
          \ spinner
          \ ))
  endif

  call setbufvar(a:bufnr, '&ma', 0)
  call setbufvar(a:bufnr, '&mod', 0)
  let esearch.last_update_at = reltime()
  let esearch.tick += 1
endfu

fu! s:header_text() abort dict
  return printf(s:finished_header,
        \ len(self.request.data),
        \ esearch#inflector#pluralize('line', len(self.request.data)),
        \ self.files_count,
        \ esearch#inflector#pluralize('file', self.files_count),
        \ )
endfu

fu! s:new_context(id, filename, begin) abort
  return {
        \ 'id': a:id,
        \ 'begin': a:begin,
        \ 'end': 0,
        \ 'filename': a:filename,
        \ 'filetype': 0,
        \ 'syntax_loaded': 0,
        \ 'lines': {},
        \ }
endfu

fu! esearch#out#win#add_context(contexts, filename, begin) abort
  let id = len(a:contexts)
  call add(a:contexts, s:new_context(id, a:filename, a:begin))
endfu

fu! s:highlight_viewport() abort
  if g:esearch_win_context_syntax_async && g:esearch#has#debounce
    let b:esearch.viewport_highlight_timer = esearch#debounce#trailing(
          \ function('s:highlight_viewport_callback', [b:esearch]),
          \ g:esearch_win_highlight_debounce_wait,
          \ b:esearch.viewport_highlight_timer)
  else
    call s:blocking_highlight_viewport(b:esearch)
  endif
endfu

fu! s:highlight_viewport_callback(esearch, timer) abort
  let a:esearch.viewport_highlight_timer = -1

  if !exists('b:esearch') || b:esearch.id != a:esearch.id
    return
  endif

  call s:blocking_highlight_viewport(a:esearch)
endfu

" TODO is heavily required to be tested
fu! s:blocking_highlight_viewport(esearch) abort
  if !a:esearch.highlights_enabled
    return
  endif

  let last_line = line('$')
  let begin = esearch#util#clip(line('w0') - g:esearch_win_viewport_highlight_extend_by, 1, last_line)
  let end   = esearch#util#clip(line('w$') + g:esearch_win_viewport_highlight_extend_by, 1, last_line)

  let state = esearch#out#win#_state()
  for context in b:esearch.contexts[state.ctx_ids_map[begin] : state.ctx_ids_map[end]]
    if !context.syntax_loaded
      call s:load_syntax(a:esearch, context)
    endif
  endfor
  call s:set_syntax_sync(a:esearch)
endfu

fu! s:set_syntax_sync(esearch) abort
  if !a:esearch.highlights_enabled
        \ || a:esearch['max_lines_found'] < 1
    return
  endif

  syntax sync clear
  exe 'syntax sync minlines='.min([
        \ float2nr(a:esearch['max_lines_found']),
        \ g:esearch#out#win#context_syntax_max_lines,
        \ ])
endfu

fu! esearch#out#win#unload_highlights() abort
  let b:esearch.highlights_enabled = 0

  " disable highlights of matching braces (3d party plugin)
  " au! parenmatch *
  let b:parenmatch = 0 " another way if parenmatch group name will become outdate

  if s:Promise.is_available()
    return s:Promise
          \.new({resolve -> timer_start(0, resolve)})
          \.then({-> esearch#out#win#_blocking_unload_syntaxes(b:esearch)})
          \.catch({reason -> execute('echoerr reason')})
  endif

  return esearch#out#win#_blocking_unload_syntaxes(b:esearch)
endfu

fu! esearch#out#win#_blocking_unload_syntaxes(esearch) abort
  if a:esearch.viewport_highlight_timer >= 0
    call timer_stop(a:esearch.viewport_highlight_timer)
  endif

  if g:esearch_out_win_nvim_lua_syntax
    syn clear
  else
    for name in map(values(a:esearch.context_syntax_regions), 'v:val.name')
      exe 'syn clear ' . name
      exe 'syn clear esearchContext_' . name
    endfor
  endif
  augroup ESearchWinHighlights
    au! * <buffer>
  augroup END
  syntax sync clear
  syntax sync maxlines=1
  call clearmatches()

  let a:esearch.context_syntax_regions = {}
endfu

fu! s:load_syntax(esearch, context) abort
  if empty(a:context.filetype)
    let a:context.filetype = esearch#ftdetect#fast(a:context.filename)
  endif

  if !has_key(s:context_syntaxes, a:context.filetype)
    let a:context.syntax_loaded = -1
    return
  endif
  let syntax_name = s:context_syntaxes[a:context.filetype]

  if !has_key(a:esearch.context_syntax_regions, syntax_name)
    let region = {
          \ 'cluster': s:include_syntax_cluster(syntax_name),
          \ 'name':    syntax_name,
          \ }
    let a:esearch.context_syntax_regions[syntax_name] = region
    exe printf('syntax region %s start="^ " end="^$" contained contains=esearchLineNr,%s',
          \ region.name,
          \ region.cluster)
  else
    let region = a:esearch.context_syntax_regions[syntax_name]
  endif

  exe printf('syntax region esearchContext_%s start="\M^%s$" end="^$" contains=esearchFilename,%s',
        \ region.name,
        \ s:String.escape_pattern(a:context.filename),
        \ region.name,
        \ )

  let len = a:context.end - a:context.begin
  if a:esearch.max_lines_found < len
    let a:esearch.max_lines_found = len
  endif
  let a:context.syntax_loaded = 1
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
        \ 'line_in_file':  function('esearch#out#win#line_in_file'),
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
  " TODO handle start via mappings
  " exe 'nmap <buffer> m :<C-U>sil cal esearch#out#win#edit()<CR>'
endfu

fu! esearch#out#win#column_in_file() abort
  return 1
  " TODO resolve on the fly
  " let col = match(m[2], pattern) + 1
endfu

fu! s:open(cmd, ...) abort
  if b:esearch.request.status !=# 0
    return
  endif

  let filename = esearch#out#win#filename()
  if !empty(filename)
    let lnum = esearch#out#win#line_in_file()
    let col = str2nr(esearch#out#win#column_in_file())
    let topline = str2nr(lnum) - (line('.') - line('w0'))
    let cmd = (a:0 ? 'noautocmd ' :'') . a:cmd
    try
      " See NOTE 1
      unsilent exe a:cmd . ' ' . filename
    catch /E325:/
      " ignore warnings about swapfiles (let user and #substitute handle them)
    catch
      unsilent echo v:exception . ' at ' . v:throwpoint
    endtry

    keepjumps call winrestview({'lnum': lnum, 'col': col - 1,'topline': topline })
    if a:0 | exe a:1 | endif
  endif
endfu

fu! esearch#out#win#line_in_file() abort
  return matchstr(getline(s:result_line()), '^\s\+\zs\d\+\ze.*')
endfu

fu! esearch#out#win#filename() abort
  let context = esearch#out#win#repo#ctx#new(b:esearch, esearch#out#win#_state()).by_line(line('.'))

  if context.id == 0
    let filename =  get(b:esearch.contexts, 1, context).filename
  else
    let filename = context.filename
  endif

  if !s:Filepath.is_absolute(filename)
    let filename = fnameescape(b:esearch.cwd . '/' . filename)
  endif

  return filename
endfu

fu! esearch#out#win#_state() abort
  if b:esearch.mode ==# 'normal'
    " Probably a better idea would be to return only paris, stored in states.
    " Storing in normal mode within undotree with a single node is not the best
    " option as it seems to create extra overhead during #update call
    " (especially on searches with thousands results; according to profiling).
    return b:esearch
  else
    return b:esearch.undotree.head.state
  endif
endfu

fu! esearch#out#win#foldtext() abort
  let filename = getline(v:foldstart)
  let last_line = getline(v:foldend)
  let entries_count = v:foldend - v:foldstart - (empty(last_line) ? 1 : 0)

  let winwidth = winwidth(0) - &foldcolumn - (&number ? strwidth(string(line('$'))) + 1 : 0)
  let lines_count_str = entries_count . ' line(s)'

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
      " If one result - move cursor on it, else - move to the next
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
    " search the begin of the line
    return 'norm! ww'
  endif
endfu

fu! s:is_file_entry() abort
  return getline(line('.')) =~# s:file_entry_pattern
endfu

fu! s:is_filename() abort
  return getline(line('.')) =~# s:filename_pattern
endfu

fu! esearch#out#win#schedule_finish(bufnr) abort
  if a:bufnr != bufnr('%')
    " Bind event to finish the search as soon as the buffer is entered
    aug ESearchWinUpdates
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
  let esearch = getbufvar(a:bufnr, 'esearch')

  let esearch.ignore_batches = 1
  call esearch#out#win#update(a:bufnr)

  if esearch.request.async
    exe printf('au! ESearchWinUpdates * <buffer=%s>', string(a:bufnr))
  endif

  if has_key(esearch, 'updates_timer')
    call timer_stop(esearch.updates_timer)
  endif
  call setbufvar(a:bufnr, '&modifiable', 1)

  if esearch.request.status !=# 0 && (len(esearch.request.errors) || len(esearch.request.data))
    call esearch#out#win#_blocking_unload_syntaxes(esearch)

    let errors = esearch.request.data + esearch.request.errors
    call esearch#util#setline(a:bufnr, 1, 'ERRORS from '.esearch.adapter.' ('.len(errors).')')
    let line = 2
    for err in errors
      call esearch#util#setline(a:bufnr, line, "\t".err)
      let line += 1
    endfor
  else
    call esearch#util#setline(a:bufnr, 1, printf(s:finished_header,
          \ len(esearch.request.data),
          \ esearch#inflector#pluralize('line', len(esearch.request.data)),
          \ esearch.files_count,
          \ esearch#inflector#pluralize('file', b:esearch.files_count),
          \))
  endif

  call setbufvar(a:bufnr, '&ma', 0)
  call setbufvar(a:bufnr, '&mod',   0)

  call esearch#out#win#edit()

  if g:esearch_out_win_nvim_lua_syntax
    call esearch#out#win#render#lua#nvim_syntax_attach_callback(b:esearch)
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
  augroup ESearchModifiable
    au! * <buffer>
    au BufWriteCmd <buffer> ++nested call s:write()
    " TODO
    au BufHidden,BufLeave <buffer>  ++nested  set nomodified
  augroup END

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

  let diff = esearch#out#win#diff#do(parsed.contexts, b:esearch.context_by_name)

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
        \ (len(lines_stats) > 1 ? 'lines' : esearch#inflector#pluralize('line', changes_count)),
        \ (diff.statistics.files > 1 ? 'across' : 'inside'),
        \ diff.statistics.files,
        \ esearch#inflector#pluralize('file', diff.statistics.files),
        \ )
  let message = 'Write changes? (' . join(lines_stats, ', ') . files_stats_text . ')'

  if esearch#ui#confirm#show(message, ['Yes', 'No']) == 1
    call esearch#writer#buffer#write(diff, b:esearch.bufnr)
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
    call esearch#log#debug(a:event,  len(v:errors))
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
  call deletebufline(bufnr(), a:event.line1 + 1, a:event.line2)
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
    let text = printf(s:finished_header,
          \ len(b:esearch.request.data),
          \ esearch#inflector#pluralize('line', len(b:esearch.request.data)),
          \ b:esearch.files_count,
          \ esearch#inflector#pluralize('file', b:esearch.files_count),
          \ )
    call setline(line1, text)
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
    call setline(line1, printf(s:finished_header,
          \ len(b:esearch.request.data),
          \ esearch#inflector#pluralize('line', len(b:esearch.request.data)),
          \ b:esearch.files_count,
          \ esearch#inflector#pluralize('file', b:esearch.files_count),
          \ ))
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
