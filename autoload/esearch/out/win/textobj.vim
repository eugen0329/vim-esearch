fu! esearch#out#win#textobj#init(esearch) abort
  if !has_key(a:esearch.pattern, 'seek_match')
    let a:esearch.pattern.seek_match = esearch#out#win#matches#pattern_each(a:esearch)
  endif
endfu

fu! esearch#out#win#textobj#match_a(count) abort
  call s:select_match(a:count, 1)
endfu

fu! esearch#out#win#textobj#match_i(count) abort
  call s:select_match(a:count, 0)
endfu

fu! s:select_match(count, is_around) abort
  let i = 0

  let [i, begin, end] = s:seek_under_cursor(i, a:count)
  if i < a:count
    let [i, begin, end] = s:seek_forward(i, a:count)
  endif

  if begin == [0,0] || end == [0,0]
    return
  endif

  if a:is_around
    call s:select_region_with_trailing_or_leading_spaces(begin, end)
  else
    call s:select_region(begin, end)
  endif
endfu

fu! s:select_region(begin, end) abort
  call cursor(a:begin)
  norm! v
  call cursor(a:end)
endfu

" Behaves like {operator}iw textobj, where trailing whitespaces if available or
" leading otherwise
fu! s:select_region_with_trailing_or_leading_spaces(begin, end) abort
  call cursor(a:begin)

  if search(b:esearch.pattern.seek_match . '\%(\S\|$\)', 'ceWn') == line('.')
    call search('\s\+\%#', 'cbW')
    norm! v
    call cursor(a:end)
  else
    norm! v
    call cursor(a:end)
    call search('\%#.\s\+', 'ceW')
  endif
endfu

fu! s:seek_forward(i, count) abort
  let [line, col] = getpos('.')[1:2]
  let i = a:i
  while i < a:count && search(b:esearch.pattern.seek_match, 'W')
    let i += 1
  endwhile
  " let begin = searchpos(b:esearch.pattern.seek_match, 'cnW')
  let begin = getpos('.')[1:2]
  let end   = searchpos(b:esearch.pattern.seek_match, 'ceWn')

  call cursor(line, col)

  return [i, begin, end]
endfu

fu! s:seek_under_cursor(i, count) abort
  let [line, col] = getpos('.')[1:2]
  let curr_line = '\%'.line.'l'
  let inline_pattern = curr_line . b:esearch.pattern.seek_match

  let begin = searchpos(inline_pattern, 'cbW')
  let end   = searchpos(inline_pattern, 'ecW')
  call cursor(line, col)

  if begin != [0, 0] && begin[1] <= col && col <= end[1]
    return [a:i + 1, begin, end]
  else
    return [a:i, [0, 0], [0, 0]]
  endif
endfu
