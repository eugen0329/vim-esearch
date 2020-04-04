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
      \ }

fu! esearch#adapter#parse#viml#legacy_funcref() abort
  return function('esearch#adapter#parse#viml#legacy')
endfu

" The method isn't split into smallar submethods to prevent redundant calls as
" it's expected to consume thousands of lines per second.
fu! esearch#adapter#parse#viml#legacy(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let results = []
  let pattern = self.exp.vim
  let separators_count = 0

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let line = a:data[i]

    if empty(line) || line ==# '--'
      let separators_count += 1
      let i += 1
      continue
    endif

    " At the moment only git adapter outputs lines that wrapped in "" when special
    " characters are encountered.
    if line[0] ==# '"'
      let res = matchlist(line, '^"\(\%(\\\\\|\\"\|.\)\{-}\)"[-:]\(\d\+\)[-:]\(.*\)$')[1:3]
      if len(res) == 3
        let [filename, lnum, text] = res

        let filename = substitute(filename, '\\\([abtnvfr"\\]\|033\)',
              \ '\=g:esearch#adapter#parse#viml#controls[submatch(1)]', 'g')
        if filereadable(filename)
          call add(results, {
                \ 'filename': filename,
                \ 'lnum':     lnum,
                \ 'text':     text})
          let i += 1
          continue
        endif
      endif
    endif

    " try to find the first readable filename
    let filename_end = 0
    while 1
      let filename_end = match(line, '[-:]\d\+[-:]', filename_end + 1)
      if filename_end < 0
        break
      endif

      " NOTE that unlike regular slicing, strpart() works with byte offsets
      " instead of char offsets, so it must be used with match()
      let filename = strpart(line, 0 , filename_end)

      if filereadable(filename)
        break
      end
    endwhile

    if filename_end > 0
      let matches = matchlist(line, '\(\d\+\)[-:]\(.*\)', filename_end)[1:2]
      if !empty(matches)
        call add(results, {
              \ 'filename': filename,
              \ 'lnum':     matches[0],
              \ 'text':     matches[1]})
      endif
    endif

    let i += 1
  endwhile

  return [results, separators_count]
endfu
