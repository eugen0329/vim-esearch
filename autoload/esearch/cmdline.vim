let g:esearch#cmdline#menu_feature_toggle = 1
if g:esearch#cmdline#menu_feature_toggle == 1
  let g:cmdline_mappings = {
        \ '<C-o>':       '<Plug>(esearch-cmdline-options-menus)',
        \ 'key':         function('esearch#util#key'),
        \ 'dict':        function('esearch#util#dict'),
        \ 'without_val':        function('esearch#util#without_val'),
        \}
  let s:comments = {
        \ '<Plug>(esearch-cmdline-options-menus)': 'Toggle regex(r) or literal(>) match',
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

if !exists('g:esearch#cmdline#select_cancelling_chars')
  let g:esearch#cmdline#select_cancelling_chars = [
        \ "\<C-a>",
        \ "\<C-e>",
        \ "\<C-c>",
        \ "\<C-o>",
        \ "\<Esc>",
        \ "\<Enter>",
        \ "\<Tab>",
        \ "\<M-b>",
        \ "\<M-f>",
        \ "\<Left>",
        \ "\<Right>",
        \ "\<S-Left>",
        \ "\<S-Right>",
        \ "\<Up>",
        \ "\<Down>",
        \ "\<S-Up>",
        \ "\<S-Down>",
        \ ]
endif

" This chars can cause undefined behavior when used as part of a string sent as
" input()'s {text} argument and need to be handled separately
let s:select_cancelling_special_chars = [
      \ "\<Esc>",
      \ "\<C-c>",
      \ "\<Enter>",
      \]

if !exists('g:esearch#cmdline#select_initial')
  let g:esearch#cmdline#select_initial = 1
endif

cnoremap <Plug>(esearch-toggle-regex)          <C-r>=<SID>run('s:invert', 'regex')<CR>
cnoremap <Plug>(esearch-toggle-case)           <C-r>=<SID>run('s:invert', 'case')<CR>
cnoremap <Plug>(esearch-toggle-word)           <C-r>=<SID>run('s:invert', 'word')<CR>
cnoremap <Plug>(esearch-cmdline-options-menus) <C-r>=<SID>run('s:options_menu')<CR>
" cnoremap <Plug>(esearch-cmdline-options-menus) <C-r>=<SID>options_menu()<CR>

cnoremap <Plug>(esearch-cmdline-interrupt) <C-c>

if g:esearch#cmdline#menu_feature_toggle == 0
  cnoremap <Plug>(esearch-cmdline-help)          <C-r>=<SID>run('esearch#cmdline#help')<CR>
else
  cnoremap <Plug>(esearch-cmdline-help)          <C-r>=<SID>run('s:options_menu')<CR>
endif

" TODO MAJOR PRIO refactoring
" a:adapter_options is used to display adapter config in the prompt (>>>)
fu! esearch#cmdline#read(cmdline_opts, adapter_options) abort
  " Preparing cmdline
  """""""""""""""""""""""""""
  let old_mapargs = s:init_mappings()
  let s:pattern = a:cmdline_opts.exp

  if a:cmdline_opts.empty_cmdline
    let g:escmdline = ''
  else
    let g:escmdline = g:esearch.regex ? a:cmdline_opts.exp.pcre : a:cmdline_opts.exp.literal
  endif
  """""""""""""""""""""""""""

  " Initial selection handling
  """""""""""""""""""""""""""
  let enter_was_pressed = 0

  if !empty(g:escmdline) && g:esearch#cmdline#select_initial
    call esearch#log#debug("!empty(g:escmdline) && g:esearch#cmdline#select_initial", '/tmp/esearch_log.txt')
    let [g:escmdline, enter_was_pressed, special_key_was_pressed, action_key] =
          \ s:handle_initial_select(g:escmdline, a:cmdline_opts.cwd, a:adapter_options)
    redraw!

    if type(action_key) == type('')
      call esearch#log#debug('type(action_key) == type()'.g:escmdline, '/tmp/esearch_log.txt')
      " throw g:escmdline
      " throw action_key
      call feedkeys(action_key)
" g:cmdline_mappings[action_key]
" .action_key
      " exe "norm :call esearch#init({'empty_cmdline': 1})\<CR>".substitute(g:escmdline, "\n", ' ', 'g')
      " return 0
    endif

    if special_key_was_pressed
      " call feedkeys(action_key)
      call esearch#log#debug('if special_key_was_pressed rerun'.g:escmdline, '/tmp/esearch_log.txt')
      " throw 3
      " throw string([g:escmdline, enter_was_pressed, special_key_was_pressed, action_key])
      " Reopen cmdline and set input using keypress emulations
      " Such a veird way is needed to handle special keys listed in
      " the g:esearch#cmdline#select_cancelling_chars
      " exe "norm :call esearch#init({'empty_cmdline': 1})\<CR>".g:escmdline
      " return 0
    endif
  else

  endif
  """""""""""

  " Reading string from user
  """""""""""""""""""""""""""
  if enter_was_pressed
    call esearch#log#debug("enter_was_pressed".g:escmdline, '/tmp/esearch_log.txt')
    let str = g:escmdline
  else
    let str = s:main_loop(a:cmdline_opts, a:adapter_options)
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
  let s:cmdpos = len(g:escmdline) + 1
  let s:list_help = 0
  let s:events = []

  let str = ''

  call esearch#log#debug('main loop start'.g:escmdline, '/tmp/esearch_log.txt')
  " Main loop
  """""""""""
  while 1
    call esearch#log#debug('main loop iteration'.g:escmdline . str, '/tmp/esearch_log.txt')
    call s:render_directory_prompt(a:cmdline_opts.cwd)
    let str = input(s:prompt(a:adapter_options), g:escmdline, 'customlist,esearch#cmdline#buff_compl')
    if empty(s:events) | break | endif

    for handler in s:events
      call esearch#log#debug('call funcref'.g:escmdline . str, '/tmp/esearch_log.txt')
      call call(handler.funcref, handler.args)
      call esearch#log#debug('call funcref after'.g:escmdline . str, '/tmp/esearch_log.txt')
    endfor

    let s:events = []
    let g:escmdline .= s:restore_cursor_position()

    redraw!
  endwhile
  return str
endfu

fu! s:handle_initial_select(cmdline, dir, adapter_options) abort
  let special_key_was_pressed = 0
  let enter_was_pressed = 0
  call esearch#log#debug('handle_initial_select.prompt', '/tmp/esearch_log.txt')
  call s:render_directory_prompt(a:dir)
  call esearch#log#debug('handle_initial_select.prompt after', '/tmp/esearch_log.txt')

  " Render virtual interface
  """""""""""""""""""""""""""
  call esearch#util#highlight('Normal', s:prompt(a:adapter_options))
  " Replace \n with \s like *input()* function argumen {text} do
  let virtual_cmdline = substitute(a:cmdline, "\n", ' ', 'g')
  call esearch#util#highlight('Visual', virtual_cmdline, 0)

  let [char, rest] = esearch#util#getchar()

  let action_key = 0
  if s:is_cmdline_mapping(char) && g:esearch#cmdline#menu_feature_toggle
    call esearch#log#debug('s:is_cmdline_mapping == 1 and return', '/tmp/esearch_log.txt')
    " let special_key_was_pressed = 1
    let action_key = char
    let special_key_was_pressed = 0
    return [virtual_cmdline, enter_was_pressed, special_key_was_pressed, action_key]

  elseif !empty(esearch#util#escape_kind(char)) || index(g:esearch#cmdline#select_cancelling_chars, char) >= 0
  " elseif index(g:esearch#cmdline#select_cancelling_chars, char) >= 0
    " Handle VERY special characters (at the moments it's <C-c>)
    " """"""""""""""""""""""""""""""""""""""""""""""""""""""
    if index(s:select_cancelling_special_chars, char) >= 0
      " TODO test
      " let enter_was_pressed = 0
      let enter_was_pressed = (char ==# "\<Enter>" ? 1 : 0)
      let special_key_was_pressed = 0
      call esearch#log#debug('select-cancelling_pressed '.index(s:select_cancelling_special_chars, char) .char , '/tmp/esearch_log.txt')

      return [a:cmdline, enter_was_pressed, special_key_was_pressed, action_key]
    endif
    " """"""""""""""""""""""""""""""""""""""""""""""""""""""

    let preserve_cmdline = 1

    if !empty(esearch#util#map_name(char))
      call esearch#log#debug('empty(esearch#util#map_name(char))', '/tmp/esearch_log.txt')
      let special_key_was_pressed = 1
      " let action_key = char
    endif
  else
    let preserve_cmdline = 0
  endif

  call esearch#log#debug('if special_key_was_pressed'.special_key_was_pressed, '/tmp/esearch_log.txt')
  if special_key_was_pressed
    let action_key = char
    let cmdline =  a:cmdline
  else
    let cmdline =  preserve_cmdline ? a:cmdline : ''
    let action_key = char
  endif

  return [cmdline, enter_was_pressed, special_key_was_pressed, action_key]
endfu

fu! s:is_cmdline_mapping(char) abort
  " NOTE mapcheck is not working
  let ma = maparg(a:char, 'c', 0,1)
  return !empty(ma)
endfu

fu! s:list_help() abort
  let s:cmdpos = getcmdpos()
  let g:escmdline = getcmdline()

  let s:list_help = 1

  call feedkeys("\<Plug>(esearch-cmdline-interrupt)", 'm')
  return ''
endfu

fu! esearch#cmdline#help() abort
  call esearch#help#cmdline(g:cmdline_mappings, s:comments)
  call getchar()
endfu

fu! s:run(func, ...) abort
  call add(s:events, {'funcref': function(a:func), 'args': a:000})
  let s:cmdpos = getcmdpos()
  let g:escmdline = getcmdline()
  call feedkeys("\<C-c>", 'n')
  " call feedkeys("\<Enter>", 'n')
  " exe "norm  " . "\<C-c>"
  call esearch#log#debug('run event after', '/tmp/esearch_log.txt')
  call esearch#log#debug(s:events, '/tmp/esearch_log.txt')
  return ''
endfu

fu! s:invert(option) abort
  call s:synchronize_regexp()
  call g:esearch.invert(a:option)
endfu

fu! s:synchronize_regexp() abort
  let s:pattern.literal = g:escmdline
  let s:pattern.pcre = g:escmdline
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
  if a:dir ==# $PWD
    return 0
  endif

  call esearch#log#debug('g:esearch#cmdline#dir_icon', '/tmp/esearch_log.txt')
  let dir = g:esearch#cmdline#dir_icon . substitute(a:dir , $PWD.'/', '', '')
  call esearch#log#debug('g:esearch#cmdline#dir_icon after', '/tmp/esearch_log.txt')
  call esearch#util#highlight('Normal', 'In ')
  call esearch#util#highlight('Directory', dir, 0)
  call esearch#log#debug("call esearch#util#highlight('Directory', dir, 0) after", '/tmp/esearch_log.txt')
  echo ''
  call esearch#log#debug("blank echo after", '/tmp/esearch_log.txt')
endfu

fu! s:restore_cursor_position() abort
  if len(g:escmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(g:escmdline) + 1 - s:cmdpos )
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

  " exacat, part, spell suggest, fuzzy, begin with
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

if g:esearch#cmdline#menu_feature_toggle == 1
  fu! s:options_menu() abort
    let prompt =
          \   "  Hotkey  Action (press a hotkey or select using j/k/enter)\n"
          \ . '  ------  -------------------------------------------------'

    call esearch#log#debug("menu start".g:escmdline, '/tmp/esearch_log.txt')
    call esearch#ui#menu#new(s:menu_items(), prompt).start()
    call esearch#log#debug("menu end".g:escmdline, '/tmp/esearch_log.txt')
  endfu

  fu s:menu_items() abort
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
    endif

    return g:esearch#cmdline#menu_items
  endfu
endif

let list = [27, 102]
let str = join(map(list, {_, val -> nr2char(val)}), '')


