" Legacy parser

fu! esearch#adapter#parse#viml#import() abort
  return function('esearch#adapter#parse#viml#parse')
endfu

let g:esearch#adapter#parse#viml#controls = {
      \  'a':  "\<C-G>",
      \  'b':  "\b",
      \  't':  "\t",
      \  'n':  "\n",
      \  'v':  "\<C-k>",
      \  'f':  "\f",
      \  'r':  "\r",
      \  '\':  '\',
      \  '"':  '"',
      \  '033':"\e",
      \}

" Parse lines in format (rev:)?filename[-:]line_number[-:]text
fu! esearch#adapter#parse#viml#parse(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let entries = []
  let pattern = self.pattern.vim
  let separators_count = 0

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let line = a:data[i]

    if empty(line) || line ==# '--'
      let separators_count += 1
      let i += 1 | continue
    endif

    if line[0] ==# '"'
      let e = s:parse_with_quoted_filename(line)
      if !empty(e) | call add(entries, e) | let i += 1 | continue | endif
    endif

    let e = s:parse_existing_filename(line)
    if !empty(e) | call add(entries, e) | let i += 1 | continue | endif
    let e = s:parse_filename_with_commit_prefix(line)
    if !empty(e) | call add(entries, e) | let i += 1 | continue | endif
  endwhile

  return [entries, separators_count]
endfu

" Parse lines in format "filename"[-:]line_number[-:]text and unwrap the filename
fu! s:parse_with_quoted_filename(line) abort
  let m = matchlist(a:line, '^"\(\%(\\\\\|\\"\|.\)\{-}\)"[-:]\(\d\+\)[-:]\(.*\)$')[1:3]
  if len(m) == 3
    let [filename, lnum, text] = m

    let filename = substitute(filename, '\\\([abtnvfr"\\]\|033\)',
          \ '\=g:esearch#adapter#parse#viml#controls[submatch(1)]', 'g')
    if filereadable(filename)
      return {'filename': filename, 'lnum': lnum, 'text': text}
    endif
  endif

  return 0
endfu

fu! s:parse_existing_filename(line) abort
  let name_end = 0
  let filename = ''

  while 1
    let name_end = match(a:line, '[-:]\d\+[-:]', name_end + 1)
    if name_end < 0 | break | endif

    let filename = strpart(a:line, 0 , name_end)
    if filereadable(filename) | break | end
  endwhile

  if name_end > 0
    let m = matchlist(a:line, '\(\d\+\)[-:]\(.*\)', name_end)[1:2]
    if empty(m) | return 0 | endif
    return {'filename': filename, 'lnum': m[0], 'text': m[1]}
  endif

  return 0
endfu

" Captures existing or the smallest filename. Will output a wrong filename if it
" contains [-:] or is removed.
fu! s:parse_filename_with_commit_prefix(line) abort
  let name_start = match(a:line, '[-:]') + 1
  if name_start == 0 | return 0 | endif
  let name_end = name_start
  let min_name_end = 0
  let filename = ''

  if a:line[name_start] ==# '"'
    let e = s:parse_with_quoted_filename(a:line[name_start:])
    if !empty(e) | return extend(e, {'filename': a:line[:name_start-1] . e.filename}) | endif
  endif

  while 1
    let name_end = match(a:line, '[-:]\d\+[-:]', name_end + 1)
    if name_end < 0 | break | endif
    if min_name_end == 0 | let min_name_end = name_end | endif

    let filename = strpart(a:line, name_start, name_end - name_start)
    if filereadable(filename) 
      return s:parse_rev(a:line, name_end)
    endif
  endwhile

  if min_name_end > 0 | return s:parse_rev(a:line, min_name_end) | endif

  return 0
endfu

fu! s:parse_rev(line, end) abort
  let m = matchlist(a:line, '\(\d\+\)[-:]\(.*\)', a:end)[1:2]
  if empty(m) | return 0 | endif
  let filename = strpart(a:line, 0, a:end)
  return {'filename': filename, 'lnum': m[0], 'text': m[1], 'rev': 1}
endfu
