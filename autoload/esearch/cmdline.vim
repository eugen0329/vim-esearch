let s:mappings = {
      \'<C-s><C-r>':  '<Plug>(esearch-regex)',
      \'<C-s><C-c>':  '<Plug>(esearch-case)',
      \'<C-s><C-w>':  '<Plug>(esearch-word)',
      \}
let s:dir_prompt = ''

cnoremap <Plug>(esearch-regex) <C-r>=<SID>invert('regex')<CR>
cnoremap <Plug>(esearch-case)  <C-r>=<SID>invert('case')<CR>
cnoremap <Plug>(esearch-word)  <C-r>=<SID>invert('word')<CR>

fu! esearch#cmdline#read(exp, dir)
  let old_mapargs = s:init_mappings()
  let s:dir_prompt = s:dir_prompt(a:dir)
  let s:pattern = a:exp
  let s:cmdline = g:esearch_settings.regex ? a:exp.pcre : a:exp.literal
  let s:cmdpos = len(s:cmdline) + 1

  let s:interrupted = 0
  while 1
    let str = input(s:prompt(), s:cmdline)

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

  let str = esearch#util#escape_str(str)
  if g:esearch_settings.regex
    let s:pattern.pcre = str
    let s:pattern.vim = esearch#regex#pcre2vim(str)
  else
    let s:pattern.literal = str
    let s:pattern.vim = str
  endif
  return s:pattern
endfu

fu! s:invert(option)
  let s:interrupted = 1
  let s:cmdpos = getcmdpos()

  let s:cmdline = getcmdline()
  if a:option == 'regex' && g:esearch_settings.recover_regex
    call s:recover_regex()
  endif

  call g:esearch_settings.invert(a:option)
  call feedkeys("\<C-c>", 'n')
  return ''
endfu

fu! s:recover_regex()
  if g:esearch_settings.regex
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

fu! s:prompt()
  let r = g:esearch_settings.stringify('regex')
  let c = g:esearch_settings.stringify('case')
  let w = g:esearch_settings.stringify('word')
  return s:dir_prompt.'pattern '.r.c.w.' '
endfu

fu! s:dir_prompt(dir)
  if a:dir ==# $PWD
    return ''
  endif
  return 'Dir: '.substitute(a:dir , $PWD, '.', '')."\n"
endfu

fu! s:get_correction()
  if len(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(s:cmdline) + 1 - s:cmdpos )
  endif
  return ''
endfu

fu! s:init_mappings()
  let mapargs =  {}
  for map in keys(s:mappings)
    " let map = s:mappings[plug]
    let mapargs[map] = maparg(map, 'c', 0, 1)
    exe "cmap " . map . ' ' . s:mappings[map]
  endfor

  return mapargs
endfu

fu! s:recover_mappings(mapargs)
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

fu! esearch#cmdline#map(map, plug)
    let s:mappings[a:map] = a:plug
endfu
