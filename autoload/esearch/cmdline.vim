let s:mappings = {
      \'<C-s><C-r>':  '<Plug>(esearch-regex)',
      \'<C-s><C-s>':  '<Plug>(esearch-case)',
      \'<C-s><C-w>':  '<Plug>(esearch-word)',
      \}
let s:dir_prompt = ''

cnoremap <Plug>(esearch-regex) <C-r>=<SID>invert('regex')<CR>
cnoremap <Plug>(esearch-case)  <C-r>=<SID>invert('case')<CR>
cnoremap <Plug>(esearch-word)  <C-r>=<SID>invert('word')<CR>

fu! esearch#cmdline#_read(exp, dir) abort
  let old_mapargs = s:init_mappings()
  let s:dir_prompt = s:dir_prompt(a:dir)
  let s:pattern = a:exp
  let s:cmdline = g:esearch.regex ? a:exp.pcre : a:exp.literal
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

  if g:esearch.regex
    let s:pattern.pcre = str
    let s:pattern.vim = esearch#regex#pcre2vim(str)
  else
    let s:pattern.literal = str
    let s:pattern.vim = substitute(substitute(str, '\\', '\\\\', 'g'), '\~', '\\~', 'g')
  endif
  return s:pattern
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

fu! s:prompt() abort
  let r = g:esearch.stringify('regex')
  let c = g:esearch.stringify('case')
  let w = g:esearch.stringify('word')
  return s:dir_prompt.'pattern '.r.c.w.' '
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
  for map in keys(s:mappings)
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
