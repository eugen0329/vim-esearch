fu! esearch#out#win#jumps#init(esearch) abort
  call extend(a:esearch, {
        \ 'jump2entry':    function('<SID>jump2entry'),
        \ 'jump2filename': function('<SID>jump2filename'),
        \ })
endfu

fu! s:jump2filename(direction, count) abort dict
  let pattern = g:esearch#out#win#filename_pattern . '\%>2l'
  let times = a:count

  if a:direction ==# 'v'
    while times > 0
      if !search(pattern, 'W') && !self.is_filename()
        call search(pattern,  'Wbe')
      endif
      let times -= 1
    endwhile
  else
    while times > 0
      if !search(pattern,  'Wbe') && !self.is_filename()
        call search(pattern, 'W')
      endif
      let times -= 1
    endwhile
  endif

  return 1
endfu

fu! s:jump2entry(direction, count) abort dict
  if self.is_blank()
    return 0
  endif

  let pattern = g:esearch#out#win#entry_pattern
  let times = a:count

  " When jumping down from the header context, it locates the second entry as
  " clicking on the header cause opening the first encountered entry below.
  if a:direction ==# 'v'
    let pattern .= line('$') <= 4 ? '\%>3l' : '\%>4l'

    while times > 0
      call search(pattern, 'W')
      let times -= 1
    endwhile
  else
    " When jumping up from the header context, it locates the first entry below
    if line('.') <= 3
      call search(pattern, 'W')
    else
      let pattern .= '\%<'.line('.').'l'
      while times > 0
        call search(pattern,  'Wb')
        let times -= 1
      endwhile
    endif
  endif

  " Locate the first column (including virtual) after a line number
  norm! 0
  let pos = searchpos('\s\+\d\+\s', 'Wne')
  call cursor(pos[0], pos[1] + 1)

  return 1
endfu
