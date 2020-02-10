let g:esearch#cmdline#menu_feature_toggle = 1
if g:esearch#cmdline#menu_feature_toggle == 1
  let g:cmdline_mappings = {
        \ '<C-o>':       '<Plug>(esearch-cmdline-open-menu)',
        \ 'key':         function('esearch#util#key'),
        \ 'dict':        function('esearch#util#dict'),
        \ 'without_val':        function('esearch#util#without_val'),
        \}
  let s:comments = {
        \ '<Plug>(esearch-cmdline-open-menu)': 'Toggle regex(r) or literal(>) match',
        \}
else
  let g:cmdline_mappings = {
        \ '<C-o><C-r>':  '<Plug>(esearch-toggle-regex)',
        \ '<C-o><C-s>':  '<Plug>(esearch-toggle-case)',
        \ '<C-o><C-w>':  '<Plug>(esearch-toggle-word)',
        \ '<C-o><C-h>':  '<Plug>(esearch-cmdline-help)',
        \ 'key':         function('esearch#util#key'),
        \ 'dict':        function('esearch#util#dict'),
        \ 'without_val':        function('esearch#util#without_val'),
        \}
  let s:comments = {
        \ '<Plug>(esearch-toggle-regex)': 'Toggle regex(r) or literal(>) match',
        \ '<Plug>(esearch-toggle-case)':  'Toggle case sensitive(c) or insensitive(>) match',
        \ '<Plug>(esearch-toggle-word)':  'Toggle only whole words matching(w)',
        \ '<Plug>(esearch-cmdline-help)': 'Show this message',
        \}
endif

if !exists('g:esearch#cmdline#dir_icon')
  if esearch#util#has_unicode()
    let g:esearch#cmdline#dir_icon = g:esearch#unicode#dir_icon
  else
    let g:esearch#cmdline#dir_icon = 'D '
  endif
endif
if !exists('g:esearch#cmdline#help_prompt')
  let g:esearch#cmdline#help_prompt = 1
endif


if !exists('g:esearch#cmdline#clear_selection_chars')
  let g:esearch#cmdline#clear_selection_chars = [
        \ "\<Del>",
        \ "\<Bs>",
        \ "\<C-w>",
        \ ]
endif
if !exists('g:esearch#cmdline#start_search_chars')
  let g:esearch#cmdline#start_search_chars = [
        \ "\<Enter>",
        \ ]
endif
if !exists('g:esearch#cmdline#cancel_selection_and_retype_chars')
  let g:esearch#cmdline#cancel_selection_and_retype_chars = [
        \ "\<Left>",
        \ "\<Right>",
        \ "\<Up>",
        \ "\<Down>",
        \ ]
endif
if !exists('g:esearch#cmdline#cancel_selection_chars')
  let g:esearch#cmdline#cancel_selection_chars = [
        \ "\<Esc>",
        \ "\<C-c>",
        \ ]
endif

if !exists('g:esearch#cmdline#select_initial')
  let g:esearch#cmdline#select_initial = 1
endif

cnoremap <Plug>(esearch-toggle-regex)      <C-r>=<SID>run('s:invert', 'regex')<CR>
cnoremap <Plug>(esearch-toggle-case)       <C-r>=<SID>run('s:invert', 'case')<CR>
cnoremap <Plug>(esearch-toggle-word)       <C-r>=<SID>run('s:invert', 'word')<CR>
cnoremap <Plug>(esearch-cmdline-open-menu) <C-r>=<SID>run('s:open_menu')<CR>

if g:esearch#cmdline#menu_feature_toggle == 0
  cnoremap <Plug>(esearch-cmdline-help) <C-r>=<SID>run('esearch#cmdline#help')<CR>
else
  cnoremap <Plug>(esearch-cmdline-help) <C-r>=<SID>run('s:open_menu')<CR>
endif

" TODO MAJOR PRIO refactoring
" a:adapter_options are used to display adapter config in the prompt (>>>)
fu! esearch#cmdline#read(esearch, adapter_options) abort
  let old_mapargs = {}
  try
    let old_mapargs = s:init_mappings()
    let s:pattern = a:esearch.exp
    let s:esearch = a:esearch

    let s:cmdline = s:esearch.regex ? a:esearch.exp.pcre : a:esearch.exp.literal
    """""""""""""""""""""""""""

    " Initial selection handling
    """""""""""""""""""""""""""
    let finish_input = 0
    if !empty(s:cmdline) && g:esearch#cmdline#select_initial
      let [s:cmdline, finish_input, retype_keys] =
            \ s:handle_initial_select(s:cmdline, a:esearch.cwd, a:adapter_options)
      redraw!

      if retype_keys isnot 0
        call feedkeys(retype_keys)
      endif
    endif
    """""""""""

    " Reading string from user
    """""""""""""""""""""""""""
    if finish_input
      let str = s:cmdline
    else
      let str = s:main_loop(a:esearch, a:adapter_options)
    endif
    """""""""""""""""""""""""""
  finally
    call s:recover_mappings(old_mapargs)
  endtry


  if empty(str)
    return {}
  endif

  " Build search expression
  """""""""""""""""""""""""""
  if s:esearch.regex
    let s:pattern.literal = str
    let s:pattern.pcre = str
    let s:pattern.vim = esearch#regex#pcre2vim(str)
  else
    let s:pattern.literal = str
    let s:pattern.pcre = str
    let s:pattern.vim = '\M'.escape(str, '\$^')
  endif
  """""""""""""""""""""""""""

  return s:pattern
endfu

fu! s:main_loop(cmdline_opts, adapter_options) abort
  let s:cmdpos = strchars(s:cmdline) + 1
  let s:list_help = 0
  let s:events = []

  let str = ''
  let s:adapter_options = a:adapter_options

  " Main loop
  """""""""""
  while 1
    call s:render_directory_prompt(a:cmdline_opts.cwd)
    let str = input(s:prompt(a:adapter_options), s:cmdline, 'customlist,esearch#completion#buffer_words')
    if empty(s:events) | break | endif

    for handler in s:events
      call call(handler.funcref, handler.args)
    endfor

    if !empty(s:events)
      redraw!
      let s:events = []
    endif

    let s:cmdline .= s:restore_cursor_position()
  endwhile
  redraw!
  return str
endfu

fu! s:handle_initial_select(cmdline, dir, adapter_options) abort
  call s:render_directory_prompt(a:dir)
  call esearch#util#highlight('Normal', s:prompt(a:adapter_options))
  call esearch#util#highlight('Visual',
        \ substitute(a:cmdline, "\n", ' ', 'g'), 0)

  let retype_keys = 0
  let cmdline =  a:cmdline
  let finish_input = 0

  let char = esearch#util#getchar()

  if index(g:esearch#cmdline#clear_selection_chars, char) >= 0
    let cmdline = ''
  elseif index(g:esearch#cmdline#start_search_chars, char) >= 0
    let finish_input = 1
  elseif index(g:esearch#cmdline#cancel_selection_and_retype_chars, char) >= 0
    let retype_keys = char
  elseif index(g:esearch#cmdline#cancel_selection_chars, char) >= 0
    " no-op
  elseif esearch#util#escape_kind(char) isnot 0
    let retype_keys = char
  elseif s:is_commandline_hotkey_prefix(char)
    let retype_keys = char
  else
    let cmdline = char
  endif

  return [cmdline, finish_input, retype_keys]
endfu

fu! s:is_commandline_hotkey_prefix(char) abort
  return mapcheck(a:char, 'c') !=# ''
endfu

fu! s:is_cmdline_mapping(char) abort
  " NOTE mapcheck is not working
  let ma = maparg(a:char, 'c', 0,1)
  return !empty(ma)
endfu

fu! s:list_help() abort
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()

  let s:list_help = 1

  call feedkeys("\<Enter>", 'm')
  return ''
endfu

fu! esearch#cmdline#help() abort
  call esearch#help#cmdline(g:cmdline_mappings, s:comments)
  call getchar()
endfu

fu! s:run(func, ...) abort
  call add(s:events, {'funcref': function(a:func), 'args': a:000})
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()
  call feedkeys("\<Enter>", 'n')
  return ''
endfu

fu! s:invert(option) abort
  call s:synchronize_regexp()
  call s:esearch.invert(a:option)
  call g:esearch.invert(a:option) " TODO reduce dependency
endfu

fu! s:synchronize_regexp() abort
  let s:pattern.literal = s:cmdline
  let s:pattern.pcre = s:cmdline
endfu

fu! s:prompt(adapter_options) abort
  let r = a:adapter_options.stringify('regex')
  let c = a:adapter_options.stringify('case')
  let w = a:adapter_options.stringify('word')

  if g:esearch#cmdline#help_prompt
    let mapping = g:cmdline_mappings.key('<Plug>(esearch-cmdline-help)')
    let help = ' (Press ' . esearch#util#stringify_mapping(mapping) . ' to list help)'
  else
    let help = ''
  endif

  return 'pattern'.help.' '.r.c.w.' '
endfu

fu! s:render_directory_prompt(cwd) abort
  " TODO weid legacy code, should be rewritten
  if a:cwd ==# getcwd() && empty(get(s:esearch, 'paths', []))
    return 0
  endif

  let [prefix, dir] = s:paths_comment(a:cwd, s:esearch.paths, s:esearch.metadata)

  call esearch#util#highlight('Normal', prefix)
  call esearch#util#highlight('Directory', dir, 0)
  echo ''
endfu

" TODO extract out of there
fu! s:paths_comment(cwd, paths, metadata) abort
  let kinds = []
  let viwable = []

  let empty_metadata = { 'wildcards': [] } " TODO
  for i in range(0, len(a:paths) - 1)
    let metadata = get(a:metadata, i, empty_metadata)
    let escaped = esearch#shell#fnameescape(a:paths[i], metadata)

    if isdirectory(a:paths[i])
      let kinds += ['directory']
      let escaped = g:esearch#cmdline#dir_icon . escaped
    elseif !empty(metadata.wildcards) || !filereadable(a:paths[i])
      let kinds += ['path']
    else
      let kinds += ['file']
    endif

    let viwable += [escaped]
  endfor

  if empty(kinds)
    return ['In directory ',
          \ g:esearch#cmdline#dir_icon . substitute(a:cwd , getcwd().'/', '', '')]
  elseif len(uniq(copy(kinds))) > 1
    return ['In ', join(viwable, ', ')]
  else
    return ['In ' . esearch#inflector#pluralize(kinds[0], len(a:paths)) . ' ', join(viwable, ', ')]
  endif
endfu

fu! s:path_kinds() abort

endfu

fu! s:restore_cursor_position() abort
  if strchars(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", strchars(s:cmdline) + 1 - s:cmdpos )
  endif
  return ''
endfu

fu! s:init_mappings() abort
  let mapargs =  {}
  let s:mapargs = []
  " TODO add support for g:esearch.default_mappings
  for map in keys(g:cmdline_mappings.dict())
    let mapargs[map] = maparg(map, 'c', 0, 1)
    exe 'cmap ' . map . ' ' . g:cmdline_mappings[map]
    let  s:mapargs += [maparg(map)]
  endfor

  return mapargs
endfu

fu! s:recover_mappings(mapargs) abort
  for map in keys(a:mapargs)
    let maparg = a:mapargs[map]
    if empty(maparg)
      exe 'cunmap '.map
    else
      let cmd  = 'silent ' . maparg.mode . (maparg.noremap ? 'nore': '')
      let cmd .= 'map ' . maparg.lhs . maparg.rhs
      exe cmd
    endif
  endfor
endfu

fu! esearch#cmdline#map(lhs, rhs) abort
  let g:cmdline_mappings[a:lhs] = '<Plug>(esearch-'.a:rhs.')'
endfu

fu! s:change_paths() abort
  redraw!


  let user_input_in_shell_format =
        \ esearch#shell#fnamesescape_and_join(s:esearch.paths, s:esearch.metadata)
  while 1
    call esearch#util#highlight('Normal', 'Input search PATHS: ')
    call esearch#util#highlight('Comment', "(example: dir/ *.json 'file with spaces.txt' etc.)", 0)
    let user_input_in_shell_format = input('',
          \ user_input_in_shell_format,
          \'customlist,esearch#cmdline#complete_files')

    let [paths, metadata, error] = esearch#shell#split(user_input_in_shell_format)
    if error isnot 0
      call esearch#util#highlight('ErrorMsg', " can't parse paths: " . error, 0)
      call getchar()
      redraw!
    else
      break
    endif
  endwhile

  let s:esearch.paths    = paths
  let s:esearch.metadata = metadata
endfu

fu! esearch#cmdline#complete_files(A,L,P) abort
  return esearch#completion#complete_files(s:esearch.cwd, a:A, a:L, a:P)
endfu

if g:esearch#cmdline#menu_feature_toggle == 1
  fu! s:open_menu() abort
    let prompt =
          \   "  Hotkey  Action (press a hotkey or select using j/k/enter)\n"
          \ . '  ------  -------------------------------------------------'

    call esearch#ui#menu#new(s:menu_items(), prompt, "\n".s:prompt(s:adapter_options) . s:cmdline).start()
  endfu

  fu! s:menu_items() abort
    if !exists('g:esearch#cmdline#menu_items')
      let g:esearch#cmdline#menu_items = []

      call add(g:esearch#cmdline#menu_items, esearch#ui#menu#item({
            \'text': 'c       toggle (c)ase sensitive match',
            \ 'shortcut': ['c', "\<C-c>", 's', "\<C-s>"],
            \ 'callback': function('<SID>invert', ['case'])}))
      call add(g:esearch#cmdline#menu_items, esearch#ui#menu#item({
            \ 'text': 'r       toggle (r)egexp match',
            \ 'shortcut': ['r', "\<C-r>"],
            \ 'callback': function('<SID>invert', ['regex'])}))
      call add(g:esearch#cmdline#menu_items, esearch#ui#menu#item({
            \ 'text': 'w       toggle (w)ord match',
            \ 'shortcut': ['w', "\<C-w>"],
            \ 'callback': function('<SID>invert', ['word'])}))
      call add(g:esearch#cmdline#menu_items, esearch#ui#menu#item({
            \ 'text': 'p       edit (p)ath',
            \ 'shortcut': ["\<C-p>", 'p'],
            \ 'callback': function('<SID>change_paths', [])}))
    endif

    return g:esearch#cmdline#menu_items
  endfu
endif
