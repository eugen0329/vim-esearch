let s:mappings = {
      \ '<C-s><C-r>':  '<Plug>(esearch-regex)',
      \ '<C-s><C-s>':  '<Plug>(esearch-case)',
      \ '<C-s><C-w>':  '<Plug>(esearch-word)',
      \ '<C-s><C-h>':  '<Plug>(esearch-cmdline-help)',
      \ 'key':         function('esearch#util#key'),
      \ 'dict':        function('esearch#util#dict'),
      \ 'without_val':        function('esearch#util#without_val'),
      \}
let s:comments = {
      \ '<Plug>(esearch-regex)': 'Toggle regex(r) or literal(>) match',
      \ '<Plug>(esearch-case)':  'Toggle case sensitive(c) or insensitive(>) match',
      \ '<Plug>(esearch-word)':  'Toggle only whole words matching(w)',
      \ '<Plug>(esearch-cmdline-help)':  'Show this message',
      \}

let s:dir_prompt = ''
let g:esearch#cmdline#help_prompt = get(g:, 'esearch#cmdline#help_prompt', 1)

cnoremap <Plug>(esearch-regex)        <C-r>=<SID>invert('regex')<CR>
cnoremap <Plug>(esearch-case)         <C-r>=<SID>invert('case')<CR>
cnoremap <Plug>(esearch-word)         <C-r>=<SID>invert('word')<CR>
cnoremap <Plug>(esearch-cmdline-help) <C-r>=<SID>help()<CR>

fu! esearch#cmdline#_read(exp, dir, options) abort
  let old_mapargs = s:init_mappings()
  let s:dir_prompt = s:dir_prompt(a:dir)
  let s:pattern = a:exp
  let s:cmdline = g:esearch.regex ? a:exp.pcre : a:exp.literal
  let s:cmdpos = len(s:cmdline) + 1

  let s:interrupted = 0
  while 1
    let str = input(s:prompt(a:options), s:cmdline)

    if s:interrupted
      let s:interrupted = 0
      let s:cmdline .= s:get_correction()
      redraw!
    else
      break
    endif
  endwhile
  unlet s:interrupted

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

" TODO refactoring
fu! s:help() abort
  let s:interrupted = 1
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()

  let help_map = "'<Plug>(esearch-cmdline-help)'"
  let help_plug = "<Plug>(esearch-cmdline-help)"

  let msg= ''
  for [m, plug] in items(s:mappings.without_val(help_map).dict())
    let msg .= printf("%10s:\t%s\n", esearch#util#stringify_mapping(m), s:comments[plug])
  endfor
  let msg .= printf("%10s:\t%s\n", esearch#util#stringify_mapping(s:mappings.key(help_map)), s:comments[help_plug])

  if esearch#cmdline#help_prompt
    let vimrc_path = '' ==# $MYVIMRC ? 'your vimrc' : $MYVIMRC
    let msg .= "\nAdd `let esearch#cmdline#help_prompt = 0` to ".vimrc_path." to disable the help prompt"
  endif

  echo msg
  call getchar()

  call feedkeys("\<C-c>", 'n')
  return ''
endfu

fu! s:invert(option) abort
  let s:interrupted = 1
  let s:cmdpos = getcmdpos()
  let s:cmdline = getcmdline()
  if a:option == 'regex' && g:esearch.recover_regex
    call s:recover_regex()
  endif

  call g:esearch.invert(a:option)
  call feedkeys("\<C-c>", 'n')
  return ''
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

  return s:dir_prompt.'pattern'.help.' '.r.c.w.' '
endfu

fu! s:dir_prompt(dir) abort
  if a:dir ==# $PWD
    return ''
  endif
  return 'Dir: '.substitute(a:dir , $PWD, '.', '')."\n"
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
    " let map = s:mappings[plug]
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

fu! esearch#cmdline#map(map, plug) abort
    let s:mappings[a:map] = a:plug
endfu
