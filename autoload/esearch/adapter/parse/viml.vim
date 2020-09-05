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
      if !empty(e) && filereadable(e.filename) | call add(entries, e) | let i += 1 | continue | endif
    endif

    let e = s:parse_existing_filename(line)
    if !empty(e) | call add(entries, e) | let i += 1 | continue | endif
    let e = s:parse_filename_with_revision_prefix(line)
    if !empty(e) | call add(entries, e) | let i += 1 | continue | endif
  endwhile

  return [entries, separators_count]
endfu

" Parse lines in format "filename"[-:]line_number[-:]text and unwrap the filename
fu! s:parse_with_quoted_filename(line) abort
  let m = matchlist(a:line, '^"\(\%(\\\\\|\\"\|.\)\{-}\)"[-:]\(\d\+\)[-:]\(.*\)$')[1:3]
  if len(m) != 3 | return 0 | endif

  let [name, lnum, text] = m
  let name = substitute(name, '\\\([abtnvfr"\\]\|033\)',
        \ '\=g:esearch#adapter#parse#viml#controls[submatch(1)]', 'g')
  return {'filename': name, 'lnum': lnum, 'text': text}
endfu

fu! s:parse_existing_filename(line) abort
  let name_end = 0
  let name = ''

  while 1
    let name_end = match(a:line, '[-:]\d\+[-:]', name_end + 1)
    if name_end < 0 | break | endif

    let name = strpart(a:line, 0 , name_end)
    if filereadable(name) | break | end
  endwhile

  if name_end > 0
    let m = matchlist(a:line, '\(\d\+\)[-:]\(.*\)', name_end)[1:2]
    if empty(m) | return 0 | endif
    return {'filename': name, 'lnum': m[0], 'text': m[1]}
  endif

  return 0
endfu

" Heuristic to captures existing quoted, existing unquoted or the smallest
" filename.
fu! s:parse_filename_with_revision_prefix(line) abort
  let name_start = match(a:line, '[-:]') + 1
  if name_start == 0 | return 0 | endif
  let name_end = name_start
  let min_name_end = 0
  let quoted_name_end = 0

  " try QUOTED
  if a:line[name_start] ==# '"'
    let quoted_entry = s:parse_with_quoted_filename(a:line[name_start :])
    if !empty(quoted_entry)
      let name = quoted_entry.filename
      call extend(quoted_entry, {'filename': a:line[: name_start-1] . name, 'rev': 1})
      if filereadable(name) | return quoted_entry | endif
      let quoted_name_end = name_start + len(name) + 2
    endif
  endif

  " try EXISTING
  while 1
    let name_end = match(a:line, '[-:]\d\+[-:]', name_end + 1)
    if name_end < 0 | break | endif
    if min_name_end == 0 | let min_name_end = name_end | endif
    let name = strpart(a:line, name_start, name_end - name_start)
    if filereadable(name) | return s:parse_from_pos(a:line, name_end, 1) | endif
  endwhile

  " try the SMALLEST of min and quoted names
  if quoted_name_end && min_name_end
    if quoted_name_end < min_name_end | return quoted_entry | endif
    return s:parse_from_pos(a:line, min_name_end, 1)
  elseif quoted_name_end
    return quoted_entry
  elseif min_name_end
    return s:parse_from_pos(a:line, min_name_end, 1)
  endif
endfu

fu! s:parse_from_pos(line, end, rev) abort
  let m = matchlist(a:line, '\(\d\+\)[-:]\(.*\)', a:end)[1:2]
  if empty(m) | return 0 | endif
  let name = strpart(a:line, 0, a:end)
  return {'filename': name, 'lnum': m[0], 'text': m[1], 'rev': a:rev}
endfu
