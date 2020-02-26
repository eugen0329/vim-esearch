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
      \ ]
" TODO
      " " \ {'lhs': '<S-j>',   'rhs': '<Plug>(esearch-win-next-file)', 'default': 1},
      " \ {'lhs': '<S-k>',   'rhs': '<Plug>(esearch-win-prev-file)', 'default': 1},

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
if !exists('g:esearch_win_disable_context_highlights_on_files_count')
  let g:esearch_win_disable_context_highlights_on_files_count = 100
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
  let g:esearch_out_win_highlight_cursor_line_number = 1
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

  if has_key(b:, 'esearch')
    call s:cleanup()
  end

  " Refresh match highlight
  setlocal ft=esearch
  " TODO
  if g:esearch.highlight_match && has_key(a:opts.exp, 'vim_match')
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
        \ 'bufnr':                    bufnr('%'),
        \ 'last_update_at':           reltime(),
        \ 'files_count':              0,
        \ 'mode':                     'normal',
        \ 'viewport_highlight_timer': -1,
        \ 'updates_timer':            -1,
        \ 'update_with_timer_start':  0,
        \ 'max_lines_found':          0,
        \ 'ignore_batches':           0,
        \ 'highlight_viewport':       0,
        \ 'tick':                     0,
        \ 'columns_map':              [],
        \ 'line_numbers_map':         [],
        \ 'contexts':                 [],
        \ 'context_by_name':          {},
        \ 'context_ids_map':          [],
        \ '_match_highlight_id':      match_highlight_id,
        \ 'broken_results':           [],
        \ 'errors':                   [],
        \ 'data':                     [],
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
    if g:esearch_out_win_highlight_cursor_line_number && &cursorline
      au CursorMoved <buffer> call s:highlight_cursor_line_number()
    endif
    if g:esearch#out#win#context_syntax_highlight
      au CursorMoved <buffer> call s:highlight_viewport()
    endif
  augroup END

  " setup blank context for header
  call s:add_context(b:esearch.contexts, '', 1)
  let header_context = b:esearch.contexts[0]
  let header_context.end = 2
  let b:esearch.context_ids_map += [header_context.id, header_context.id]
  let b:esearch.columns_map += [0, 0]
  let b:esearch.line_numbers_map += [0, 0]

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

fu! s:highlight_cursor_line_number() abort
  if has_key(b:, 'esearch_linenr_id')
    try
      call matchdelete(b:esearch_linenr_id)
    catch /E803:/
      " a workaround for nvim when going to help (isn't reproduced for vim)
      return
    endtry
  endif
  let b:esearch_linenr_id = matchadd('esearchCursorLineNr', '^\s\+\d\+\s\%' . line('.') . 'l', -1)
endfu

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
          exe printf('au User %s call s:update_by_backend_callbacks_until_1st_batch_is_rendered(%d)',
                \ event, a:esearch.bufnr)
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
      for [func_name, event] in items(a:esearch.request.events)
        exe printf('au User %s call esearch#out#win#%s(%s)', event, func_name, string(bufnr('%')))
      endfor
    augroup END
  endif
endfu

" will render <= 2 * batch_size (usually much less than 2x)
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
  exe printf('au! ESearchWinUpdates * <buffer=%s>', string(a:esearch.bufnr))
  for event in values(a:esearch.request.events)
    exe printf('au! ESearchWinUpdates User %s ', event)
  endfor
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
          \ || (request.finished && data_size - request.cursor - 1 <= esearch.last_batch_size)
      let [from, to] = [request.cursor, data_size - 1]
      let request.cursor = data_size
    else
      let [from, to] = [request.cursor, request.cursor + esearch.batch_size - 1]
      let request.cursor += esearch.batch_size
    endif

    let parsed = esearch.parse(data, from, to)
    call s:render_results(a:bufnr, parsed, esearch)
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

fu! s:add_context(contexts, filename, begin) abort
  let id = len(a:contexts)
  call add(a:contexts, s:new_context(id, a:filename, a:begin))
endfu

fu! s:render_results(bufnr, parsed, esearch) abort
  let line = line('$') + 1
  let parsed = a:parsed

  let i = 0
  let limit = len(parsed)
  let lines = []

  while i < limit
    if has_key(parsed[i], 'bufnr')
      let filename = bufname(parsed[i].bufnr)
    else
      let filename = substitute(parsed[i].filename, a:esearch.cwd_prefix, '', '')
    endif

    if g:esearch_win_ellipsize_results
      let text = esearch#util#ellipsize(
            \ parsed[i].text,
            \ parsed[i].col,
            \ a:esearch.context_width.left,
            \ a:esearch.context_width.right,
            \ g:esearch#util#ellipsis)
    else

      let text = parsed[i].text
    endif

    if filename !=# a:esearch.contexts[-1].filename
      let a:esearch.contexts[-1].end = line

      if a:esearch.highlights_enabled &&
            \ len(a:esearch.contexts) > g:esearch_win_disable_context_highlights_on_files_count
        let a:esearch.highlights_enabled = 0
        call s:unload_highlights(a:esearch)
      end

      call add(lines, '')
      call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
      call add(a:esearch.columns_map, 0)
      call add(a:esearch.line_numbers_map, 0)
      let line += 1

      call add(lines, filename)
      call s:add_context(a:esearch.contexts, filename, line)
      let a:esearch.context_by_name[filename] = a:esearch.contexts[-1]
      call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
      call add(a:esearch.columns_map, 0)
      call add(a:esearch.line_numbers_map, 0)
      let a:esearch.files_count += 1
      let line += 1
      let a:esearch.contexts[-1].filename = filename
    endif

    call add(lines, printf(' %3d %s', parsed[i].lnum, text))
    call add(a:esearch.columns_map, parsed[i].col)
    call add(a:esearch.line_numbers_map, parsed[i].lnum)
    call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
    let a:esearch.contexts[-1].lines[parsed[i].lnum] = parsed[i].text
    let line += 1
    let i    += 1
  endwhile

  call esearch#util#append_lines(lines)
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

  let state = s:state()
  for context in b:esearch.contexts[state.context_ids_map[begin] : state.context_ids_map[end]]
    if !context.syntax_loaded
      call s:load_syntax(a:esearch, context)
    endif
  endfor
endfu

fu! s:set_syntax_sync(esearch) abort
  if !a:esearch.highlights_enabled
        \ || a:esearch['max_lines_found'] < 1
    return
  endif

  syntax sync clear
  exe 'syntax sync minlines='.min([
        \ a:esearch['max_lines_found'],
        \ g:esearch#out#win#context_syntax_max_lines,
        \ ])
endfu

fu! s:unload_highlights(esearch) abort
  " disable highlights of matching braces (3d party plugin)
  " au! parenmatch *
  let b:parenmatch = 0 " another way if parenmatch group name will become outdate

  if s:Promise.is_available()
    return s:Promise
          \.new({resolve -> timer_start(0, resolve)})
          \.then({-> s:blocking_unload_syntaxes(a:esearch)})
          \.catch({reason -> execute('echoerr reason')})
  endif

  return s:blocking_unload_syntaxes(a:esearch)
endfu

fu! s:blocking_unload_syntaxes(esearch) abort
  if a:esearch.viewport_highlight_timer >= 0
    call timer_stop(a:esearch.viewport_highlight_timer)
  endif

  for name in map(values(a:esearch.context_syntax_regions), 'v:val.name')
    exe 'syn clear ' . name
    exe 'syn clear esearchContext_' . name
  endfor
  augroup ESearchWinHighlights
    au! * <buffer>
  augroup END
  syntax sync clear
  syntax sync maxlines=1

  let a:esearch.context_syntax_regions = {}
endfu

fu! s:load_syntax(esearch, context) abort
  if a:context.filetype is# 0
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
  return get(b:esearch.columns_map, s:result_line(), 1)
endfu

fu! s:open(cmd, ...) abort
  if b:esearch.request.status !=# 0
    return
  endif

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

fu! esearch#out#win#line_in_file() abort
  return matchstr(getline(s:result_line()), '^\s\+\zs\d\+\ze.*')
endfu

fu! esearch#out#win#filename() abort
  let context = esearch#out#win#repo#ctx#new(b:esearch, s:state()).by_line(line('.'))
  if context.id == 0
    return get(b:esearch.contexts, 1, context).filename
  endif
  return context.filename
endfu

fu! s:state() abort
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
    for event in values(esearch.request.events)
      exe printf('au! ESearchWinUpdates User %s ', event)
    endfor
  endif

  if has_key(esearch, 'updates_timer')
    call timer_stop(esearch.updates_timer)
  endif

  call s:set_syntax_sync(esearch)
  call setbufvar(a:bufnr, '&modifiable', 1)

  if esearch.request.status !=# 0 && (len(esearch.request.errors) || len(esearch.request.data))
    call s:blocking_unload_syntaxes(esearch)

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
    au BufHidden,BufLeave <buffer>  ++nested          set nomodified
  augroup END

  try
    sil exe 'nunmap <buffer> t'
    sil exe 'nunmap <buffer> T'
    sil exe 'nunmap <buffer> i'
    sil exe 'nunmap <buffer> I'
    sil exe 'nunmap <buffer> s'
    sil exe 'nunmap <buffer> S'
    sil exe 'nunmap <buffer> o'
  catch /E31: No such mapping/
  endtry

  let b:esearch.undotree = esearch#undotree#new({
        \ 'context_ids_map': b:esearch.context_ids_map,
        \ 'line_numbers_map': b:esearch.line_numbers_map,
        \ })
  call esearch#changes#listen_for_current_buffer(b:esearch.undotree)
  call esearch#changes#add_observer(function('esearch#out#win#handle_changes'))
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
  " return
  if a:event.id =~# '^n-motion' || a:event.id =~# '^v-' || a:event.id =~# '^V-line-delete-'
    call esearch#out#win#delete_multiline#handle(a:event)
  elseif a:event.id =~# 'undo'
    call s:handle_undo_traversal(a:event)
  elseif a:event.id =~# 'n-inline\d\+' || a:event.id =~# 'v-inline'
    let debug = s:handle_normal__inline(a:event)
  elseif a:event.id =~# 'i-inline'
    let debug = s:handle_insert__inline(a:event)
  elseif  a:event.id =~# 'i-delete-newline'
    let debug = s:handle_insert__delete_newlines(a:event)
  elseif a:event.id =~# 'join'
    call esearch#out#win#unsupported#handle(a:event)
  elseif a:event.id =~# 'cmdline'
    call esearch#out#win#cmdline#handle(a:event)
  else
    call b:esearch.undotree.synchronize()
    "" the feature is toggled until commandline and visual-block handling is ready
    " call esearch#out#win#unsupported#handle(a:event)
  endif

  if g:esearch#env isnot 0
    call assert_equal(line('$') + 1, len(b:esearch.undotree.head.state.context_ids_map))
    call assert_equal(line('$') + 1, len(b:esearch.undotree.head.state.line_numbers_map))
    " call esearch#log#debug(a:event,  len(v:errors))
  endif
endfu

fu! s:handle_undo_traversal(event) abort
  call b:esearch.undotree.checkout(a:event.changenr)
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
    call setline(line1, printf(s:finished_header,
          \ len(b:esearch.request.data),
          \ esearch#inflector#pluralize('line', len(b:esearch.request.data)),
          \ b:esearch.files_count,
          \ esearch#inflector#pluralize('file', b:esearch.files_count),
          \ ))
  elseif line1 == 2 || line1 == context.end && context.end != line('$')
    call setline(line1, '')
    call feedkeys("\<Esc>")
  elseif line1 == context.begin
    call setline(line1, context.filename)

  elseif line1 > 2 && col1 < strlen(linenr) + 1
    " VIRTUAL INTERFACE WITH LINE NUMBERS IS AFFECTED:

    if a:event.id ==# 'i-inline-add'
      " Recovered text:
      "   - take   linenr
      "   - concat with extracted chars inserted within a virtual interface
      "   - concat with the rest of the text with removed leftovers from
      "   virtual interface and inserted chars
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
  let recover_cursor = ''

  if line1 == 1
    call setline(line1, printf(s:finished_header,
          \ len(b:esearch.request.data),
          \ esearch#inflector#pluralize('line', len(b:esearch.request.data)),
          \ b:esearch.files_count,
          \ esearch#inflector#pluralize('file', b:esearch.files_count),
          \ ))

    if mode() ==# 'i'
      let recover_cursor = "\<Esc>"
    endif
  elseif line1 == 2
    " TODO undef mode
    if mode() ==# 'i'
      let recover_cursor = "\<Esc>"
    endif
  elseif line1 == context.begin
    " it's a filename, restoring
    call setline(line1, context.filename)

    if mode() ==# 'i'
      let recover_cursor = "\<Down>\<End>"
    endif

  elseif line1 > 2 && col1 < strlen(linenr) + 1
    " VIRTUAL INTERFACE WITH LINE NUMBERS IS AFFECTED:

    if col2 < strlen(linenr) + 1 " deletion happened within linenr, the text is untouched
      " recover linenr and remove leading previous linenr leftover
      let text = linenr . text[strlen(linenr) - (col2 - col1 + 1) :]
    else " deletion starts within linenr, ends within the text
      " recover linenr and remove leading previous linenr leftover
      let text = linenr . text[ col1 - 1 :]
    endif
    " let text = linenr . text[ [col1, col2, strlen(linenr)] :]
    call setline(line1, text)

    if mode() ==# 'i'
      let recover_cursor = "\<End>"
    endif
  endif

  call b:esearch.undotree.synchronize()
  if !empty(recover_cursor)
    call feedkeys(recover_cursor)
  endif
endfu
