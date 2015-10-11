fu! easysearch#cmdline#read(initial)
  let s:int_pending = 0
  let s:cmdline = a:initial
  let s:cmdpos = len(s:cmdline) + 1

  let repeat = 1
  while repeat
    let str = input('pattern '.g:esearch_settings['regex'].'>> ', s:cmdline)
    if s:int_pending
      let s:int_pending = 0
      let s:cmdline .= s:get_correction()
    else
      let repeat = 0
    endif
  endwhile
  unlet s:int_pending

  return s:cmdline
endfu

fu! s:get_correction()
  if len(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(s:cmdline) + 1 - s:cmdpos )
  endif
  return ''
endfu

fu! easysearch#cmdline#invert(option)
  let s:cmdline = getcmdline()
  let s:cmdpos = getcmdpos()
  let s:int_pending = 1
  call g:esearch_settings.invert(a:option)
  call feedkeys("\<C-c>", 'n')
  return ''
endfu
