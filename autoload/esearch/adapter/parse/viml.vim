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

" Legacy parser
" Parse lines in format filename[-:]line_number[-:]text
fu! esearch#adapter#parse#viml#parse(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let entries = []
  let pattern = self.pattern.vim
  let separators_count = 0
  let git = self.adapter ==# 'git'

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let line = a:data[i]

    if empty(line) || line ==# '--'
      let separators_count += 1
      let i += 1
      continue
    endif

    if (line[0] ==# '"' && s:parse_with_quoted_filename(entries, line))
          \ || s:parse_existing_filename(entries, line)
          \ || s:parse_filename_with_commit_prefix(entries, line)
    endif
    " call s:parse_existing_filename(entries, line)

    let i += 1
  endwhile

  return [entries, separators_count]
endfu

fu! s:parse_with_quoted_filename(entries, line) abort
  let m = matchlist(a:line, '^"\(\%(\\\\\|\\"\|.\)\{-}\)"[-:]\(\d\+\)[-:]\(.*\)$')[1:3]
  if len(m) == 3
    let [filename, lnum, text] = m

    let filename = substitute(filename, '\\\([abtnvfr"\\]\|033\)',
          \ '\=g:esearch#adapter#parse#viml#controls[submatch(1)]', 'g')
    if filereadable(filename)
      call add(a:entries, {'filename': filename, 'lnum': lnum, 'text': text})
      return 1
    endif
  endif

  return 0
endfu

fu! s:parse_existing_filename(entries, line) abort
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
    call add(a:entries, {'filename': filename, 'lnum': m[0], 'text': m[1]})
    return 1
  endif

  return 0
endfu

" Captures existing or the smallest filename. Will output a wrong filename if it
" contains [-:] or is removed.
fu! s:parse_filename_with_commit_prefix(entries, line)
  let name_start = match(a:line, '[-:]') + 1
  let name_end = name_start
  let min_name_end = 0
  let filename = ''

  while 1
    let name_end = match(a:line, '[-:]\d\+[-:]', name_end + 1)
    if name_end < 0 | break | endif
    if min_name_end == 0 | let min_name_end = name_end | endif

    let filename = strpart(a:line, name_start, name_end - name_start)
    if filereadable(filename) 
      return s:add_git_entry(a:entries, a:line, strpart(a:line, 0, name_end), min_name_end)
    endif
  endwhile

  if min_name_end > 0
    return s:add_git_entry(a:entries, a:line, strpart(a:line, 0, min_name_end), min_name_end)
  endif

  return 0
endfu

fu! s:add_git_entry(entries, line, name, end) abort
  let m = matchlist(a:line, '\(\d\+\)[-:]\(.*\)', a:end)[1:2]
  if empty(m) | return 0 | endif
  call add(a:entries, {'filename': a:name, 'lnum': m[0], 'text': m[1], 'git': 1})
  return 1
endfu
