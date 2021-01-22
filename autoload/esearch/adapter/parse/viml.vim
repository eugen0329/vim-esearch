" Legacy parsers

fu! esearch#adapter#parse#viml#import() abort
  return s:export
endfu

" Parse lines in JSON format from semgrep adapter
fu! s:semgrep(data, from, to) abort dict
  if empty(a:data) | return [[], 0] | endif
  let entries = []
  let errors = 0

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let json = json_decode(a:data[i])

    if has_key(json, 'errors') && !empty(json.errors)
      let errors = map(json.errors, 'v:val.long_msg')
    endif

    if has_key(json, 'results') && !empty(json.results)
      for result in json.results
        let filename = result.path
        let l = result.start.line
        for text in split(result.extra.lines, "\n")
          call add(entries, {'filename': filename, 'lnum': string(result.start.line), 'text': text})
          let l += l
        endfor
      endfor

      if l - 1 != result['end'].line
        echo 'semgrep: wrong lines parsing'
      endif
    endif

    let i += 1
  endwhile

  let lines_delta = a:to + 1 - a:from - len(entries)
  return [entries, lines_delta, errors]
endfu

" Parse lines in format (rev:)?filename[-:]line_number[-:]column_number[-:]text
fu! s:with_col(data, from, to) abort dict
  if empty(a:data) | return [[], 0] | endif
  let entries = []
  let lines_delta = 0

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let line = a:data[i]

    if empty(line) || line ==# '--'
      let lines_delta += 1
      let i += 1 | continue
    endif

    let name_end = 0
    let name = ''
    while 1
      let name_end = match(line, '[-:]\d\+[-:]\d\+[-:]', name_end + 1)
      if name_end < 0 | break | endif
      let name = strpart(line, 0 , name_end)
      if filereadable(name)
        let m = matchlist(line, '\(\d\+\)[-:]\d\+[-:]\(.*\)', name_end)[1:2]
        if !empty(m)
          call add(entries, {'filename': name, 'lnum': m[0], 'text': m[1]})
        endif
        break
      endif
    endwhile

    let i += 1
  endwhile

  return [entries, lines_delta, 0]
endfu

let g:esearch#adapter#parse#viml#controls = {
      \ 'a':  "\<c-g>",
      \ 'b':  "\b",
      \ 't':  "\t",
      \ 'n':  "\n",
      \ 'v':  "\<c-k>",
      \ 'f':  "\f",
      \ 'r':  "\r",
      \ '\':  '\',
      \ '"':  '"',
      \ '033':"\e",
      \}

" Parse lines in format (rev:)?filename[-:]line_number[-:]text
fu! s:generic(data, from, to) abort dict
  if empty(a:data) | return [[], 0] | endif
  let entries = []
  let lines_delta = 0

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let line = a:data[i]

    if empty(line) || line ==# '--'
      let lines_delta += 1
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
    let i += 1 " TODO notify error
  endwhile

  return [entries, lines_delta, 0]
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

let s:export = {
        \ 'generic':  function('<SID>generic'),
        \ 'with_col': function('<SID>with_col'),
        \ 'semgrep':  function('<SID>semgrep'),
        \}
