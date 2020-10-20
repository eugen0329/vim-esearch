let s:filename_re = g:esearch#out#win#filename_re . '\%>2l'

" Applied rules for better UX to save keystrokes:
" - Jumps DOWN and UP skip the first and the last target respectivly.
"   Ex: when navigating down to the filename from line 1, column 1, the cursor
"   moves to the second filename.
" - To jump to the first or the last target, use the opposite direction jump.
"   Ex: for moving cursor from line 1 col 1 to the first entry, use jump UP.

fu! esearch#out#win#jumps#init(esearch) abort
  call extend(a:esearch, {
        \ 'jump2entry':    function('<SID>jump2entry'),
        \ 'jump2filename': function('<SID>jump2filename'),
        \ 'jump2dirname':  function('<SID>jump2dirname'),
        \ })
endfu

fu! s:jump2filename(count1, ...) abort dict
  if get(a:, 1) is# 'v'
    norm! gv
  endif

  " When jumping down from the header context, it locates the second filenme
  if a:count1 > 0
    if line('.') <= 2
      norm! 3gg0
    endif
    let times = a:count1
    while times > 0
      if !search(s:filename_re, 'W') && !self.is_filename()
        " if no filenames forward (the cursor is within the last ctx) - jump to
        " the last filename
        call search(s:filename_re,  'Wbe')
        break
      endif
      let times -= 1
    endwhile
  else
    " When jumping up from the header context, it locates the first filename below
    if line('.') <= 2
      norm! 3gg0
      return 1
    endif

    norm! 0
    " if no filenames forward (the cursor is within the last ctx) - jump to
    " the filename before the last ctx
    if !self.is_filename() && !search(s:filename_re,  'Wn')
      call search(s:filename_re,  'Wbe')
    endif

    let times = -a:count1
    while times > 0
      if !search(s:filename_re,  'Wbe') && !self.is_filename()
        " if no filenames backward (the cursor is within the first ctx) - jump to
        " the first filename
        call search(s:filename_re, 'W')
        break
      endif
      let times -= 1
    endwhile
  endif

  return 1
endfu

fu! s:jump2entry(count1, ...) abort dict
  if self.is_blank()
    return 0
  endif

  if get(a:, 1) is# 'v'
    norm! gv
  endif

  let pattern = g:esearch#out#win#entry_re

  " When jumping down from the header context, it locates the second entry as
  " clicking on the header cause opening the first encountered entry below.
  if a:count1 > 0
    let times = a:count1
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
      let times = -a:count1
      while times > 0
        call search(pattern,  'Wb')
        let times -= 1
      endwhile
    endif
  endif

  " Locate the first column/virtual column after a line number
  norm! ^f l

  return 1
endfu

fu! s:jump2dirname(count1, ...) abort dict
  if get(a:, 1) is# 'v'
    norm! gv
  endif

  let last_filename = self.filename()
  let last_dirname = fnamemodify(last_filename, ':h')
  let first_dirname = last_dirname

  if a:count1 > 0
    if line('.') <= 2
      norm! 3gg0
    endif
    norm! 0

    " the cursor is within the last ctx - jump to the filename before the last ctx
    if !self.is_filename() && !search(s:filename_re,  'Wn')
      call search(s:filename_re,  'Wbe')
      return s:inline_jump2basename()
    endif

    let last_dirname = s:jump2dirname_down(self, a:count1, last_filename, last_dirname)
  else
    if line('.') <= 2 " When jumping up from the header context, it locates the first filename below
      norm! 3gg0
      return s:inline_jump2basename()
    endif

    let last_dirname = s:jump2dirname_up(self, a:count1, last_filename, last_dirname)
  endif

  return s:inline_jump2basename()
endfu

fu! s:jump2dirname_down(esearch, count1, last_filename, last_dirname) abort
  let [last_filename, last_dirname, times] = [a:last_filename, a:last_dirname, a:count1]

  while times > 0
    if !search(s:filename_re, 'W') && !a:esearch.is_filename()
      " if no filenames forward (the cursor is within the last ctx) - jump to
      " the last filename
      call search(s:filename_re,  'Wbe')
      break
    endif

    let filename = a:esearch.filename()
    if filename ==# last_filename | break | endif
    let last_filename = filename

    let dirname = fnamemodify(filename, ':h')
    if last_dirname !=# dirname
      let [last_dirname, times] = [dirname, times - 1]
    endif
  endwhile

  return last_dirname
endfu

fu! s:jump2dirname_up(esearch, count1, last_filename, last_dirname) abort
  let [last_filename, last_dirname] = [a:last_filename, a:last_dirname]

  " Start searching from the filename
  if a:esearch.is_filename()
    norm! 0
  else
    call search(s:filename_re,  'Wb')
  endif

  " if no filenames forward (the cursor is within the last ctx) - jump to
  " the filename before the last ctx
  if !a:esearch.is_filename() && !search(s:filename_re,  'Wn')
    call search(s:filename_re,  'Wb')
  endif

  let times = -a:count1
  while times > 0
    if !search(s:filename_re,  'Wbe') && !a:esearch.is_filename()
      " if no filenames backward (the cursor is within the first ctx) - jump to
      " the first filename
      call search(s:filename_re, 'W')
      break
    endif

    let filename = a:esearch.filename()
    if filename ==# last_filename | break | endif
    let last_filename = filename

    let dirname = fnamemodify(filename, ':h')
    if last_dirname !=# dirname
      let [last_dirname, times] = [dirname, times - 1]
    endif
  endwhile

  return last_dirname
endfu

fu! s:inline_jump2basename() abort
  norm! $T/
  if col('.') == col('$') - 1
    norm! 0
  endif

  return 1
endfu
