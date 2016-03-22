let s:mappings = {
      \ '<C-s><C-r>':  '<Plug>(esearch-toggle-regex)',
      \ '<C-s><C-s>':  '<Plug>(esearch-toggle-case)',
      \ '<C-s><C-w>':  '<Plug>(esearch-toggle-word)',
      \ '<C-s><C-h>':  '<Plug>(esearch-cmdline-help)',
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
  let g:esearch#cmdline#dir_icon = "🗀 "
endif
if !exists('g:esearch#cmdline#help_prompt')
  let g:esearch#cmdline#help_prompt = 1
endif
if !exists('g:esearch#cmdline#fallback_keys')
  let g:esearch#cmdline#fallback_keys = [
        \ "\<C-a>",
        \ "\<C-e>",
        \ "\<C-c>",
        \ "\<Esc>",
        \ "\<Enter>",
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
let s:select_cancelling_chars = [
      \ "\<Esc>",
      \ "\<C-c>",
      \ "\<Enter>",
      \]

if !exists('g:esearch#cmdline#select_initial')
  let g:esearch#cmdline#select_initial = 1
endif

cnoremap <Plug>(esearch-toggle-regex)        <C-r>=<SID>run('s:invert', 'regex')<CR>
cnoremap <Plug>(esearch-toggle-case)         <C-r>=<SID>run('s:invert', 'case')<CR>
cnoremap <Plug>(esearch-toggle-word)        <C-r>=<SID>run('s:invert', 'word')<CR>
cnoremap <Plug>(esearch-cmdline-help)        <C-r>=<SID>run('s:help')<CR>

" TODO refactoring
fu! esearch#cmdline#_read(exp, dir, options) abort
  let old_mapargs = s:init_mappings()
  let s:pattern = a:exp
  let s:cmdline = g:esearch.regex ? a:exp.pcre : a:exp.literal

  let enter_was_pressed = 0
  if !empty(s:cmdline) && g:esearch#cmdline#select_initial
    " TODO
    let [s:cmdline, enter_was_pressed] = s:handle_initial_select(s:cmdline, a:dir, a:options)
    redraw!
  endif

  if enter_was_pressed
    let str = s:cmdline
  else
    let s:cmdpos = len(s:cmdline) + 1
    let s:interrupted = 0
    let s:list_help = 0
    let s:pending = []
    while 1
      call s:dir_prompt(a:dir)
      let str = input(s:prompt(a:options), s:cmdline)

      if empty(s:pending)
        break
      endif
      for handler in s:pending
        call call(handler.funcref, handler.args)
      endfor
      let s:pending = []
      let s:cmdline .= s:get_correction()
      redraw!
    endwhile
    unlet s:interrupted
  endif

  call s:recover_mappings(old_mapargs)

  if empty(str)
    return {}
  endif

  if g:esearch.regex
    let s:pattern.pcre = str
    let s:pattern.vim = esearch#regex#pcre2vim(str)
  else
    let s:pattern.literal = str
    let s:pattern.vim = substitute(substitute(str, '\\', '\\\\', 'g'), '\~', '\\~', 'g')
  endif
  return s:pattern
endfu

fu! s:handle_initial_select(cmdline, dir, options)
  let enter_is_pressed = 0
  call s:dir_prompt(a:dir)
  call esearch#util#highlight('Normal', s:prompt(a:options))
  " Replace \n with \s like input function argumen {text} do
  call esearch#util#highlight('Visual', substitute(a:cmdline, "\n", ' ', 'g'), 0)

  let char = getchar()

  " If contains multibyte it will be wrapped as a string (else - number)
  if type(char) !=# type('')
    let char = nr2char(char)
  endif
  let printable = strtrans(char)

  if index(g:esearch#cmdline#fallback_keys, char) >= 0
    if index(s:select_cancelling_chars, char) >= 0)
      let enter_is_pressed = (char == "\<Enter>" ? 1 : 0)
      return [a:cmdline, enter_is_pressed]
    endif

    let is_fallback = 1

    let map_rhs = esearch#util#map_rhs(printable)
    if !empty(map_rhs)
      let char = map_rhs
    endif
  else
    let is_fallback = 0
  endif

  let cmdline =  is_fallback ? a:cmdline . char : char

  return [cmdline, enter_is_pressed]
endfu

fu! s:list_help()
  let s:interrupted = 1
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()

  let s:list_help = 1

  call feedkeys("\<C-c>", 'n')
  return ''
endfu

fu! s:help() abort
  let help_plug = "<Plug>(esearch-cmdline-help)"
  let help_map = '"'. help_plug .'"'

  for [m, plug] in items(s:mappings.without_val(help_map).dict())
    call esearch#util#highlight('Title', printf('%10s:', esearch#util#stringify_mapping(m)))
    call esearch#util#highlight('Normal', '  '.s:comments[plug])
    echo ""
  endfor
  let map = printf("%10s:", esearch#util#stringify_mapping(s:mappings.key(help_map)))
  call esearch#util#highlight('Title', map)
  call esearch#util#highlight('Normal', '  '.s:comments[help_plug])

  if g:esearch#cmdline#help_prompt
    echo "\n"
    call esearch#util#highlight('Normal',    'Add `')
    call esearch#util#highlight('Statement', 'let ')
    call esearch#util#highlight('Identifier', 'esearch#cmdline#help_prompt')
    call esearch#util#highlight('Operator', ' = ')
    call esearch#util#highlight('Normal', '0` to ')
    call esearch#util#highlight('Bold', '' ==# $MYVIMRC ? 'your vimrc' : $MYVIMRC)
    call esearch#util#highlight('Normal', ' to disable help prompt')
  endif

  call getchar()
endfu

fu! s:run(func, ...)
  call add(s:pending, {'funcref': function(a:func), 'args': a:000})
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()
  call feedkeys("\<C-c>", 'n')
  return ''
endfu

fu! s:invert(option) abort
  if a:option == 'regex' && g:esearch.recover_regex
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

fu! s:prompt(options) abort
  let r = a:options.stringify('regex')
  let c = a:options.stringify('case')
  let w = a:options.stringify('word')

  if g:esearch#cmdline#help_prompt
    let mapping = s:mappings.key('"<Plug>(esearch-cmdline-help)"')
    let help = ' (Press ' . esearch#util#stringify_mapping(mapping) . ' to list help)'
  else
    let help = ''
  endif

  return 'pattern'.help.' '.r.c.w.' '
endfu

fu! s:dir_prompt(dir) abort
  if a:dir ==# $PWD
    return 0
  endif
  call esearch#util#highlight('Normal', 'In ')
  call esearch#util#highlight('Directory', g:esearch#cmdline#dir_icon.substitute(a:dir , $PWD.'/', '', ''))
  call esearch#util#highlight('Normal', '')
endfu

fu! s:get_correction() abort
  if len(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(s:cmdline) + 1 - s:cmdpos )
  endif
  return ''
endfu

fu! s:init_mappings() abort
  let mapargs =  {}
  for map in keys(s:mappings.dict())
    let mapargs[map] = maparg(map, 'c', 0, 1)
    exe "cmap " . map . ' ' . s:mappings[map]
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
