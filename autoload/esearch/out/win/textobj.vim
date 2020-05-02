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

fu! s:select_match(count, with_trailing_spaces) abort
  let i = 0

  let [i, begin, end] = s:seek_under_cursor(i, a:count)
  if i < a:count
    let [i, begin, end] = s:seek_forward(i, a:count)
  endif

  if begin != [0,0] && end != [0,0]
    call cursor(begin)
    if a:with_trailing_spaces
      let end = searchpos(b:esearch.pattern.seek_match . '\m\s*', 'cneW')
    endif
    norm! v
    call cursor(end)
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
  let end   = searchpos(b:esearch.pattern.seek_match, 'cneW')

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
