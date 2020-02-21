let esearch#adapter#grep_like#multiple_files_Search_format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'
let esearch#adapter#grep_like#single_file_search_format = '^\(\d\{-}\)\:\(.\{-}\)$'

fu! esearch#adapter#grep_like#joined_paths(esearch) abort
  if empty(a:esearch.paths)
    let joined_paths = a:esearch.cwd
  else
    let paths = deepcopy(a:esearch.paths)
    let escaped = []
    for i in range(0, len(paths)-1)
      call add(escaped, fnameescape(paths[i]))
    endfor

    let joined_paths = join(escaped, ' ')
  endif

  return joined_paths
endfu

fu! esearch#adapter#grep_like#set_results_parser(esearch) abort
  if a:esearch.is_single_file()
    let a:esearch.parse = function('esearch#adapter#grep_like#parse_from_1_file')
    let a:esearch.format = g:esearch#adapter#grep_like#single_file_search_format
  else
    let a:esearch.parse = function('esearch#adapter#grep_like#parse')
    let a:esearch.format = g:esearch#adapter#grep_like#multiple_files_Search_format
  endif

  let a:esearch.expand_filename = function('esearch#adapter#ag_like#expand_filename')
endfu

fu! esearch#adapter#grep_like#parse_from_1_file(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let format = self.format
  let results = []
  let pattern = self.format

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let m = matchlist(a:data[i], format)[1:3]
    if len(m) == 3
      let col = match(m[2], pattern) + 1
      if !col | let col = 1 | endif

      call add(results, {
            \ 'filename': s:expand_escaped_glob(self.paths[0]),
            \ 'lnum': m[0], 'col': col, 'text': m[1] })
    else
      if index(self.broken_results, a:data[i]) < 0
        call add(self.broken_results, {'after': a:data[i-1], 'res': a:data[i]})
      endif
    endif
    let i += 1
  endwhile

  return results
endfu

fu! esearch#adapter#grep_like#parse(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let format = self.format
  let results = []
  let pattern = self.exp.vim

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let m = matchlist(a:data[i], format)[1:3]

    if len(m) != 3
      if index(self.broken_results, a:data[i]) < 0
        call add(self.broken_results, {'after': a:data[i-1], 'res': a:data[i]})
      endif
    else
      let g:m = m
      let col = match(m[2], pattern) + 1
      if !col | let col = 1 | endif
      call add(results, {
            \ 'filename': m[0],
            \ 'lnum': m[1], 'col': col, 'text': m[2] })
    endif
    let i += 1
  endwhile

  return results
endfu

fu! s:expand_escaped_glob(str) abort
  let re_escaped='\%(\\\)\@<!\%(\\\\\)*\zs\\'
  return substitute(a:str, re_escaped . '\*', '*', 'g')
endfu
