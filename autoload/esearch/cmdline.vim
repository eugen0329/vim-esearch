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
" a:adapter_options is used to display adapter config in the prompt (>>>)
fu! esearch#cmdline#read(opts, adapter_options) abort
  " Preparing cmdline
  """""""""""""""""""""""""""
  let old_mapargs = s:init_mappings()
  let s:pattern = a:opts.exp
  let s:opts = a:opts

  let s:cmdline = g:esearch.regex ? a:opts.exp.pcre : a:opts.exp.literal
  """""""""""""""""""""""""""

  " Initial selection handling
  """""""""""""""""""""""""""
  let finish_input = 0
  if !empty(s:cmdline) && g:esearch#cmdline#select_initial
    let [s:cmdline, finish_input, retype_keys] =
          \ s:handle_initial_select(s:cmdline, a:opts.cwd, a:adapter_options)
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
    let str = s:main_loop(a:opts, a:adapter_options)
  endif
  """""""""""""""""""""""""""

  call s:recover_mappings(old_mapargs)

  if empty(str)
    return {}
  endif

  " Build search expression
  """""""""""""""""""""""""""
  if g:esearch.regex
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
    let str = input(s:prompt(a:adapter_options), s:cmdline, 'customlist,esearch#cmdline#buff_compl')
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
  call g:esearch.invert(a:option)
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

fu! s:render_directory_prompt(dir) abort
  if a:dir ==# $PWD && empty(s:opts.paths)
    return 0
  endif

  if empty(s:opts.paths)
    let dir = g:esearch#cmdline#dir_icon . substitute(a:dir , $PWD.'/', '', '')
  else
    let dir = g:esearch#cmdline#dir_icon 
          \ . join(map(s:opts.paths, "substitute(v:val , '".$PWD."/', '', '')"), ' ')
  endif
  call esearch#util#highlight('Normal', 'In ')
  call esearch#util#highlight('Directory', dir, 0)
  echo ''
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

" borrowed from oblique and incsearch
fu! esearch#cmdline#buff_compl(A, ...) abort
  let chars = map(split(a:A, '.\zs'), 'escape(v:val, "\\[]^$.*")')
  let fuzzy_pat = join(
        \ extend(map(chars[0 : -2], "v:val . '[^' .v:val. ']\\{-}'"),
        \ chars[-1:-1]), '')

  let spell_pat = a:A
  let spell_save = &spell
  let &spell = 1
  try
    let spell_pat = substitute(spell_pat, '\k\+', '\=s:spell_suggests(submatch(0))', 'g')
  finally
    let &spell = spell_save
  endtry

  " exact, part, spell suggest, fuzzy, begins with
  let e = []
  let p = []
  let s = []
  let f = []
  let b = []

  let words = esearch#util#buff_words()
  " because of less typos in small words
  let word_len = strlen(a:A)
  if word_len < 4
    call filter(words, 'word_len <= strlen(v:val)')
  endif

  for w in words
    if w == a:A
      call add(e, w)
    elseif w =~ '^'.a:A
      call add(b, w)
    elseif w =~ a:A
      call add(p, w)
    elseif word_len > 2 && w =~ spell_pat
      call add(s, w)
    elseif word_len > 2 && w =~ fuzzy_pat
      call add(f, w)
    endif
  endfor

  call sort(f, 'esearch#util#compare_len')
  call sort(s, 'esearch#util#compare_len')
  call sort(e, 'esearch#util#compare_len')
  call sort(p, 'esearch#util#compare_len')
  return e + b + p + s + f
endfu

function! s:spell_suggests(word) abort
  return printf('\m\(%s\)', join(spellsuggest(a:word, 10), '\|'))
endfunction

fu! s:paths() abort
  redraw!
  let s:opts.paths = split(input('Directories:', join(s:opts.paths, ' '), 'file'), ' ')
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
            \ 'shortcut': ["\<C-p>", "p"],
            \ 'callback': function('<SID>paths', [])}))
    endif

    return g:esearch#cmdline#menu_items
  endfu
endif
