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
let s:header = 'Matches in %d lines, %d file(s)'
let s:finished_header = 'Matches in %d lines, %d file(s). Finished.'
let s:file_entry_pattern = '^\s\+\d\+\s\+.*'
let s:filename_pattern = '^[^ ]' " '\%>2l'

if get(g:, 'esearch#out#win#keep_fold_gutter', 0)
  let s:blank_line_fold = 0
else
  let s:blank_line_fold = '<1'
endif

if !exists('g:esearch#out#win#context_syntax_highlight')
  let g:esearch#out#win#context_syntax_highlight = 0
endif

let s:syntax_regexps = {
      \ 'light_ruby': 'Rakefile\|Capfile\|Gemfile\|\%(\.rb\|\.ru\)$',
      \ 'light_eruby': '\%(\.erb\)$',
      \ 'yaml': '\%(yaml\|\.yml\)$',
      \}
if exists('g:esearch#out#win#syntax_regeps')
  call extend(s:syntax_regexps, g:esearch#out#win#syntax_regeps)
endif
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
    let match_highlight_id = matchadd('ESearchMatch', a:opts.exp.vim_match, -1)
  else
    let match_highlight_id = -1
  endif

  if a:opts.request.async
    augroup ESearchWinAutocmds
      au! * <buffer>
      " Events can be: update, finish etc.
      for [func_name, event] in items(a:opts.request.events)
        exe printf('au User %s call esearch#out#win#%s(%s)', event, func_name, string(bufnr('%')))
      endfor
      call esearch#backend#{a:opts.backend}#init_events()
    augroup END
  endif

  call s:init_mappings()
  call s:init_commands()

  setlocal modifiable
  exe '1,$d_'
  call esearch#util#setline(bufnr('%'), 1, printf(s:header, 0, 0))
  setlocal undolevels=-1 " Disable undo
  setlocal nomodifiable
  setlocal nobackup
  setlocal noswapfile
  setlocal nonumber
  let &buflisted = g:esearch#out#win#buflisted
  setlocal foldcolumn=0
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal foldlevel=2
  setlocal foldexpr=esearch#out#win#foldexpr()
  setlocal foldtext=esearch#out#win#foldtext()
  setlocal foldmethod=expr

  let b:esearch = extend(a:opts, {
        \ 'prev_filename':       '',
        \ 'ignore_batches':     0,
        \ '_columns':            {},
        \ '_match_highlight_id': match_highlight_id,
        \ '__broken_results':    [],
        \ 'errors':              [],
        \ 'data':                [],
        \ 'syn_regions_loaded':                [],
        \ 'without':             function('esearch#util#without')
        \})

  call extend(b:esearch.request, {
        \ 'files_count': 0,
        \ 'bufnr':     bufnr('%'),
        \ 'data_ptr':     0,
        \ 'out_finish':   function('esearch#out#win#_is_render_finished')
        \})

  call esearch#backend#{b:esearch.backend}#run(b:esearch.request)

  if !b:esearch.request.async
    call esearch#out#win#finish(bufnr('%'))
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
    return 1
  endif
  let esearch = getbufvar(a:bufnr, 'esearch')
  let ignore_batches = esearch.ignore_batches
  let request = esearch.request

  let data = esearch.request.data
  let data_size = len(data)
  if data_size > request.data_ptr
    if ignore_batches || data_size - request.data_ptr - 1 <= esearch.batch_size
      let [from, to] = [request.data_ptr, data_size - 1]
      let request.data_ptr = data_size
    else
      let [from, to] = [request.data_ptr, request.data_ptr + esearch.batch_size - 1]
      let request.data_ptr += esearch.batch_size
    endif

    let parsed = esearch#adapter#{esearch.adapter}#parse_results(
          \ data, from, to, esearch.__broken_results, esearch.exp.vim)

    call setbufvar(a:bufnr, '&ma', 1)
    call s:render_results(a:bufnr, parsed, esearch)
    " TODO len(esearch._columns) is used to prevent %lines_count+1% bug in vim8
    call esearch#util#setline(a:bufnr, 1, printf(s:header, len(esearch._columns), request.files_count))
    call setbufvar(a:bufnr, '&ma', 0)
    call setbufvar(a:bufnr, '&mod', 0)
  endif
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
    let filename    = substitute(parsed[i].filename, sub_expression, '', '')
    let context  = s:context(parsed[i].text, a:esearch)

    if filename !=# a:esearch.prev_filename
      let a:esearch.request.files_count += 1
      if g:esearch#out#win#context_syntax_highlight
        for [s,r] in items(s:syntax_regexps)
          if filename =~ r
            if index(a:esearch.syn_regions_loaded, s) < 0
              let c = s:load_context_syntax(s)
              call add(a:esearch.syn_regions_loaded, s)
            else
              let c = '@'.toupper(s)
            endif
            break
          endif
        endfor
      endif

      " exe printf('syntax region contextRUBY  matchgroup=easysearchLnum start="^\%4dl\s\+\d\+" end="^$" keepend contains=@RUBY', line)
      call esearch#util#setline(a:bufnr, line, '')
      let line += 1
      call esearch#util#setline(a:bufnr, line, filename)
      let line += 1

      " exe printf('syntax region contextRUBY  matchgroup=easysearchLnum start="^\%%%dl\s\+\d\+" end="^$" keepend contains=@RUBY', line)
      if exists('c')
        exe printf('syntax region context%s '
              \ .'start="^\%%%dl\s\+\d\+\s" end="^$" keepend contains=%s,esearchLnum', toupper(s), line, c)
        unlet c
      endif
    endif


    call esearch#util#setline(a:bufnr, line, printf(' %3d %s', parsed[i].lnum, context))
    let a:esearch._columns[line] = parsed[i].col
    let a:esearch.prev_filename = filename
    let line += 1
    let i    += 1
  endwhile
endfu

fu! s:load_context_syntax(ft) abort
  let c = '@' . toupper(a:ft)

  if exists('b:current_syntax')
    let syntax_save = b:current_syntax
    unlet b:current_syntax
  endif

  exe 'syntax include' c 'syntax/' . a:ft . '.vim'

  if exists('syntax_save')
    let b:current_syntax = syntax_save
  elseif exists('b:current_syntax')
    unlet b:current_syntax
  endif
  return c
endfu

fu! s:context(line, esearch) abort
  return esearch#util#btrunc(a:line,
                           \ match(a:line, a:esearch.exp.vim),
                           \ a:esearch.context_width.l,
                           \ a:esearch.context_width.r)
endfu

fu! esearch#out#win#map(lhs, rhs) abort
  call esearch#util#add_map(s:mappings, a:lhs, '<Plug>(esearch-win-'.a:rhs.')')
endfu

fu! s:init_commands() abort
  let s:win = {
        \ 'line_in_file':   function('s:line_in_file'),
        \ 'open':          function('s:open'),
        \ 'filename':      function('s:filename'),
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
  " nnoremap <silent><buffer> <Plug>(esearch-win-Nop)           <Nop>

  for mapping in s:mappings
    if !g:esearch.default_mappings && mapping.default | continue | endif

    exe 'nmap <buffer> ' . mapping.lhs . ' ' . mapping.rhs
  endfor
endfu

fu! s:open(cmd, ...) abort
  let fname = s:filename()
  if !empty(fname)
    let ln = s:line_in_file()
    let col = get(b:esearch._columns, s:result_line(), 1)
    let cmd = (a:0 ? 'noautocmd ' :'') . a:cmd
    try
      " See NOTE 1
      unsilent exe a:cmd . ' ' . fnameescape(b:esearch.cwd . '/' . fname)
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

fu! s:line_in_file() abort
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

  if esearch.request.async
    exe printf('au! ESearchWinAutocmds * <buffer=%s>', string(a:bufnr))
    for [func_name, event] in items(esearch.request.events)
      exe printf('au! ESearchWinAutocmds User %s ', event)
    endfor
  endif

  " Update using all remaining request.data
  let esearch.ignore_batches = 1
  call esearch#out#win#update(a:bufnr)

  call setbufvar(a:bufnr, '&ma', 1)

  if esearch.request.status !=# 0 && (len(esearch.request.errors) || len(esearch.request.data))
    let errors = esearch.request.data + esearch.request.errors
    call esearch#util#setline(a:bufnr, 1, 'ERRORS from '.esearch.adapter.' ('.len(errors).')')
    let line = 2
    for err in errors
      call esearch#util#setline(a:bufnr, line, "\t".err)
      let line += 1
    endfor
    " norm! gggqG
  else
    call esearch#util#setline(a:bufnr, 1, printf(s:finished_header, len(esearch._columns), esearch.request.files_count))
  endif

  call setbufvar(a:bufnr, '&ma', 0)
  call setbufvar(a:bufnr, '&mod',   0)
endfu

" For some reasons s:_is_render_finished fails in Travis
fu! esearch#out#win#_is_render_finished() dict abort
  return self.data_ptr == len(self.data)
endfu

