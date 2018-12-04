let s:mappings = {
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
      \ '<Plug>(esearch-cmdline-help)':  'Show this message',
      \}

if !exists('g:esearch#cmdline#dir_icon')
  if esearch#util#has_unicode()
    let g:esearch#cmdline#dir_icon = '🗀 '
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
        \ "\<Up>",
        \ "\<Down>",
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

cnoremap <Plug>(esearch-toggle-regex)        <C-r>=<SID>run('s:invert', 'regex')<CR>
cnoremap <Plug>(esearch-toggle-case)         <C-r>=<SID>run('s:invert', 'case')<CR>
cnoremap <Plug>(esearch-toggle-word)         <C-r>=<SID>run('s:invert', 'word')<CR>
cnoremap <Plug>(esearch-cmdline-help)        <C-r>=<SID>run('s:help')<CR>


" TODO MAJOR PRIO refactoring
" a:adapter_options is used to display adapter config in the prompt (>>>)
fu! esearch#cmdline#read(cmdline_opts, adapter_options) abort
  " Preparing cmdline
  """""""""""""""""""""""""""
  let old_mapargs = s:init_mappings()
  let s:pattern = a:cmdline_opts.exp

  if a:cmdline_opts.empty_cmdline
    let s:cmdline = ''
  else
    let s:cmdline = g:esearch.regex ? a:cmdline_opts.exp.pcre : a:cmdline_opts.exp.literal
  endif
  """""""""""""""""""""""""""

  " Initial selection handling
  """""""""""""""""""""""""""
  let enter_was_pressed = 0

  if !empty(s:cmdline) && g:esearch#cmdline#select_initial
    let [s:cmdline, enter_was_pressed, special_key_was_pressed] =
          \ s:handle_initial_select(s:cmdline, a:cmdline_opts.cwd, a:adapter_options)
    redraw!

    if special_key_was_pressed
      " Reopen cmdline and set input using keypress emulations
      " Such a veird way is needed to handle special keys listed in
      " the g:esearch#cmdline#select_cancelling_chars
      exe "norm :call esearch#init({'empty_cmdline': 1})\<CR>".s:cmdline
      return 0
    endif
  else

  endif
  """""""""""

  " Reading string from user
  """""""""""""""""""""""""""
  if enter_was_pressed
    let str = s:cmdline
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
    let s:pattern.pcre = str
    let s:pattern.vim = esearch#regex#pcre2vim(str)
  else
    let s:pattern.literal = str
    let s:pattern.vim = '\V'.escape(str, '\')
  endif
  """""""""""""""""""""""""""

  return s:pattern
endfu

fu! s:main_loop(cmdline_opts, adapter_options) abort
  let s:cmdpos = len(s:cmdline) + 1
  let s:list_help = 0
  let s:events = []

  " Main loop
  """""""""""
  while 1
    call s:render_directory_prompt(a:cmdline_opts.cwd)
    let str = input(s:prompt(a:adapter_options), s:cmdline, 'customlist,esearch#cmdline#buff_compl')

    if empty(s:events)
      break
    endif

    for handler in s:events
      call call(handler.funcref, handler.args)
    endfor

    let s:events = []
    let s:cmdline .= s:restore_cursor_position()

    redraw!
  endwhile
  return str
endfu

fu! s:handle_initial_select(cmdline, dir, adapter_options) abort
  let special_key_was_pressed = 0
  let enter_was_pressed = 0
  call s:render_directory_prompt(a:dir)

  " Render virtual interface
  """""""""""""""""""""""""""
  call esearch#util#highlight('Normal', s:prompt(a:adapter_options))
  " Replace \n with \s like *input()* function argumen {text} do
  let virtual_cmdline = substitute(a:cmdline, "\n", ' ', 'g')
  call esearch#util#highlight('Visual', virtual_cmdline, 0)
  """""""""""""""""""""""""""

  " Read char from user
  """""""""""""""""""""""""""
  let char = getchar()
  " getchar() results example:
  "   KeyPress | getchar()     | Type
  "   <M-c>    | '<80><fc>^Hc' | String
  "     a      |     97        | Integer
  "     b      |     98        | Integer
  " Convert everything to String
  if type(char) !=# type('')
    let char = nr2char(char)
  endif
  """""""""""""""""""""""""""

  if index(g:esearch#cmdline#select_cancelling_chars, char) >= 0
    " Handle VERY special characters (<Enter>, <Esc> or <C-c>)
    " """"""""""""""""""""""""""""""""""""""""""""""""""""""
    if index(s:select_cancelling_special_chars, char) >= 0
      let enter_was_pressed = (char ==# "\<Enter>" ? 1 : 0)
      let special_key_was_pressed = 0
      return [a:cmdline, enter_was_pressed, special_key_was_pressed]
    endif
    " """"""""""""""""""""""""""""""""""""""""""""""""""""""

    let preserve_cmdline = 1

    if !empty(esearch#util#map_name(char))
      let special_key_was_pressed = 1
    endif
  else
    let preserve_cmdline = 0
  endif

  if special_key_was_pressed
    let cmdline =  virtual_cmdline . char
  else
    let cmdline =  preserve_cmdline ? a:cmdline . char : char
  endif

  return [cmdline, enter_was_pressed, special_key_was_pressed]
endfu

fu! s:list_help() abort
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()

  let s:list_help = 1

  call feedkeys("\<C-c>", 'n')
  return ''
endfu

fu! s:help() abort
  call esearch#help#cmdline(s:mappings, s:comments)
  call getchar()
endfu

fu! s:run(func, ...) abort
  call add(s:events, {'funcref': function(a:func), 'args': a:000})
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()
  call feedkeys("\<C-c>", 'n')
  return ''
endfu

fu! s:invert(option) abort
  if a:option ==# 'regex' && g:esearch.recover_regex
    call s:recover_regex()
  endif
  call g:esearch.invert(a:option)
endfu

fu! s:recover_regex() abort
  if g:esearch.regex
    if s:cmdline == s:pattern.pcre
      let s:cmdline = s:pattern.literal
    else
      let s:pattern.pcre = s:cmdline
      let s:cmdline = esearch#regex#pcre_sanitize(s:cmdline)
      let s:pattern.literal = s:cmdline
    endif
  else
    if s:cmdline == s:pattern.literal
      let s:cmdline = s:pattern.pcre
    else
      let s:pattern.literal = s:cmdline
      let s:pattern.pcre = s:cmdline
    endif
  endif
endfu

fu! s:prompt(adapter_options) abort
  let r = a:adapter_options.stringify('regex')
  let c = a:adapter_options.stringify('case')
  let w = a:adapter_options.stringify('word')

  if g:esearch#cmdline#help_prompt
    let mapping = s:mappings.key('<Plug>(esearch-cmdline-help)')
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

  let dir = g:esearch#cmdline#dir_icon . substitute(a:dir , $PWD.'/', '', '')
  call esearch#util#highlight('Normal', 'In ')
  call esearch#util#highlight('Directory', dir, 0)
  echo ''
endfu

fu! s:restore_cursor_position() abort
  if len(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(s:cmdline) + 1 - s:cmdpos )
  endif
  return ''
endfu

fu! s:init_mappings() abort
  let mapargs =  {}
  " TODO add support for g:esearch.default_mappings
  for map in keys(s:mappings.dict())
    let mapargs[map] = maparg(map, 'c', 0, 1)
    exe 'cmap ' . map . ' ' . s:mappings[map]
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
  let s:mappings[a:lhs] = '<Plug>(esearch-'.a:rhs.')'
endfu

" borrowed from oblique and incsearch
fu! esearch#cmdline#buff_compl(A, C, ...) abort
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
