fu! esearch#out#win#textobj#init(esearch) abort
  let a:esearch.pattern.seek_match = esearch#out#win#matches#pattern_each(a:esearch) . '\%>1l'
endfu

fu! esearch#out#win#textobj#match_a(is_visual, count1) abort
  call s:select_match(a:is_visual, a:count1, 1)
endfu

fu! esearch#out#win#textobj#match_i(is_visual, count1) abort
  call s:select_match(a:is_visual, a:count1, 0)
endfu

fu! s:select_match(is_visual, count1, is_around) abort
  let i = 0
  let s:view = winsaveview()

  let [i, begin, end] = s:seek_under_cursor(i, a:count1)
  if i < a:count1
    let [i, begin, end] = s:seek_forward(i, a:count1)
  endif

  if begin == [0,0] || end == [0,0]
    return s:cancel(a:is_visual)
  endif

  if a:is_around
    call s:select_region_with_trailing_or_leading_spaces(begin, end)
  else
    call s:select_region(begin, end)
  endif
endfu

" inspired by junegunn code and CountJump implementation
fu! s:cancel(is_visual) abort
  if a:is_visual
    exec 'norm! gv'
  elseif index(['c', 'd'], esearch#out#win#modifiable#operator()) >= 0
    let undo_seq = "\<esc>:undo|redraw"
          \."|echo 'esearch: no more matches found ahead'"
          \."|call esearch#out#win#textobj#winrestview()\<cr>"
    call feedkeys(undo_seq, 'n')
  endif
endfu

fu! s:select_region(begin, end) abort
  call cursor(a:begin)
  norm! v
  call cursor(a:end)
endfu

fu! esearch#out#win#textobj#winrestview() abort
  call winrestview(s:view)
  let s:view = {}
endfu

" Behaves like {operator}iw textobj, where trailing whitespaces if available or
" leading otherwise
fu! s:select_region_with_trailing_or_leading_spaces(begin, end) abort
  call cursor(a:begin)

  if search(b:esearch.pattern.seek_match . '\%(\S\|$\)', 'ecWn') == line('.')
    call search('\s\+\%#', 'bcW')
    norm! v
    call cursor(a:end)
  else
    norm! v
    call cursor(a:end)
    call search('\%#.\s\+', 'ecW')
  endif
endfu

fu! s:seek_forward(i, count1) abort
  let [line, col] = getpos('.')[1:2]
  let i = a:i
  while i < a:count1 && search(b:esearch.pattern.seek_match, 'W')
    let i += 1
  endwhile
  let begin = getpos('.')[1:2]
  let end   = searchpos(b:esearch.pattern.seek_match, 'ecWn')

  call cursor(line, col)

  return [i, begin, end]
endfu

fu! s:seek_under_cursor(i, count1) abort
  let [line, col] = getpos('.')[1:2]
  let curr_line_re = '\%'.line.'l'
  let inline_match_re = curr_line_re . b:esearch.pattern.seek_match

  let begin = searchpos(inline_match_re, 'bcW')
  let end   = searchpos(inline_match_re, 'ecW')
  call cursor(line, col)

  if begin != [0, 0] && begin[1] <= col && col <= end[1]
    return [a:i + 1, begin, end]
  else
    return [a:i, [0, 0], [0, 0]]
  endif
endfu
