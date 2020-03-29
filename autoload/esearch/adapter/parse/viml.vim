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

fu! esearch#adapter#parse#viml#legacy(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let results = []
  let pattern = self.exp.vim

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let line = a:data[i]

    if line[0] ==# '"'
      let res = matchlist(line, '^"\(\%(\\\\\|\\"\|.\)\{-}\)"\:\(\d\{-}\)[-:]\(.*\)$')[1:3]
      if len(res) != 3
        let i += 1
        continue
      endif

      let [filename, lnum, text] = res

      let filename = substitute(filename, '\\\([abtnvfr"\\]\|033\)',
            \ '\=g:esearch#adapter#parse#viml#controls[submatch(1)]', 'g')
      if filereadable(filename)
        call add(results, {
              \ 'filename': filename,
              \ 'lnum':     lnum,
              \ 'text':     text})
        continue
      endif
    endif

    let offset = 0
    while 1
      let idx = stridx(line, ':', offset)

      if idx < 0
        break
      endif

      let filename = line[0 : idx - 1]
      let offset = idx + 1

      if filereadable(filename)
        break
      end
    endwhile

    if idx > 0
      let matches = matchlist(line, '\(\d\+\)[-:]\(.*\)', offset)[1:2]
      if !empty(matches)
        call add(results, {
              \ 'filename': filename,
              \ 'lnum':     matches[0],
              \ 'text':     matches[1]})
      endif
    endif

    let i += 1
  endwhile

  return results
endfu
