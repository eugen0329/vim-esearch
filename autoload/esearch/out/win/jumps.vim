fu! esearch#out#win#jumps#init(esearch) abort
  call extend(a:esearch, {
        \ 'jump2entry':    function('<SID>jump2entry'),
        \ 'jump2filename': function('<SID>jump2filename'),
        \ })
endfu

fu! s:jump2filename(direction, count, ...) abort dict
  let filename_re = g:esearch#out#win#filename_re . '\%>2l'
  let times = a:count

  if get(a:, 1) is# 'v'
    norm! gv
  endif

  " When jumping down from the header context, it locates the second filenme
  if a:direction ==# 1
    if line('.') <= 2
      call search(filename_re, 'W')
    endif
    while times > 0
      if !search(filename_re, 'W') && !self.is_filename()
        " if no filenames forward (the cursor is within the last ctx) - jump to
        " the last filename
        call search(filename_re,  'Wbe')
        break
      endif
      let times -= 1
    endwhile
  else
    " When jumping up from the header context, it locates the first filename below
    if line('.') <= 2
      call search(filename_re, 'W')
    else
      norm! 0

      " if no filenames forward (the cursor is within the last ctx) - jump to
      " the filename before the last ctx
      if !self.is_filename() && !search(filename_re,  'Wn')
        call search(filename_re,  'Wbe')
      endif

      while times > 0
        if !search(filename_re,  'Wbe') && !self.is_filename()
          " if no filenames backward (the cursor is within the first ctx) - jump to
          " the first filename
          call search(filename_re, 'W')
          break
        endif
        let times -= 1
      endwhile
    endif
  endif

  return 1
endfu

fu! s:jump2entry(direction, count, ...) abort dict
  if self.is_blank()
    return 0
  endif

  if get(a:, 1) is# 'v'
    norm! gv
  endif

  let pattern = g:esearch#out#win#entry_re
  let times = a:count

  " When jumping down from the header context, it locates the second entry as
  " clicking on the header cause opening the first encountered entry below.
  if a:direction ==# 1
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
