fu! easysearch#cmdline#read(initial)
  let s:int_pending = 0
  let s:cmdline = a:initial
  let s:cmdpos = len(s:cmdline) + 1
  let old_mappings = s:init_mappings()
  while 1
    let str = input(s:prompt(), s:cmdline)
    if s:int_pending
      let s:int_pending = 0
      let s:cmdline .= s:get_correction()
    else
      break
    endif
  endwhile
  unlet s:int_pending

  call s:restore_mappings(old_mappings)
  return str
endfu

fu! s:prompt()
  let r = g:esearch_settings.stringify('regex')
  return 'pattern '.r.'>> '
endfu

fu! s:get_correction()
  if len(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(s:cmdline) + 1 - s:cmdpos )
  endif
  return ''
endfu

fu! s:init_mappings()
  let mappings =  {
        \'<C-r><C-e>': maparg('<C-r><C-e>', 'c', 0, 1)
        \}
  exe "cnoremap <C-r><C-e> <C-r>=<SID>invert('regex')<CR>"
  return mappings
endfu

fu! s:restore_mappings(mappings)
  for map in keys(a:mappings)
    let maparg = a:mappings[map]
    if empty(maparg)
      exe 'cunmap '.map
    else
      let cmd = 'silent '.maparg.mode.(maparg.noremap ? 'nore': '').'map '.maparg.lhs
      let cmd .= maparg.rhs
      exe cmd
    endif
  endfor
endfu

fu! s:invert(option)
  let s:int_pending = 1
  let s:cmdline = getcmdline()
  let s:cmdpos = getcmdpos()
  call g:esearch_settings.invert(a:option)
  call feedkeys("\<C-c>", 'n')
  return ''
endfu
