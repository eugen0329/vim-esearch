let esearch#adapter#ag_like#multiple_files_Search_format = '^\(.\{-}\)\:\(\d\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'
let esearch#adapter#ag_like#single_file_search_format = '^\(\d\+\)\:\(\d\+\)\:\(.*\)$'

fu! esearch#adapter#ag_like#joined_paths(esearch) abort
  if empty(a:esearch.paths)
    let joined_paths = a:esearch.cwd
  else
    let paths = deepcopy(a:esearch.paths)
    let escaped = []
    for i in range(0, len(paths)-1)
      call add(escaped, esearch#shell#fnameescape(paths[i], a:esearch.metadata[i]))
    endfor

    let joined_paths = join(escaped, ' ')
  endif

  return joined_paths
endfu

fu! esearch#adapter#ag_like#set_results_parser(esearch) abort
  if a:esearch.is_single_file()
    let a:esearch.parse_results = function('esearch#adapter#ag_like#parse_results_from_single_file')
    let a:esearch.format = g:esearch#adapter#ag_like#single_file_search_format
  else
    let a:esearch.parse_results = function('esearch#adapter#ag_like#parse_results')
    let a:esearch.format = g:esearch#adapter#ag_like#multiple_files_Search_format
  endif
endfu

fu! esearch#adapter#ag_like#parse_results_from_single_file(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let format = self.format
  let results = []

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let m = matchlist(a:data[i], format)[1:3]
    if len(m) == 3
      call add(results, {
            \ 'filename': s:expand_escaped_glob(self.paths[0]),
            \ 'lnum': m[0], 'col': m[1], 'text': m[2] })
    else
      if index(self.broken_results, a:data[i]) < 0
        call add(self.broken_results, {'after': a:data[i-1], 'res': a:data[i]})
      endif
    endif
    let i += 1
  endwhile

  return results
endfu

fu! esearch#adapter#ag_like#parse_results(data, from, to) abort dict
  if empty(a:data) | return [] | endif
  let format = self.format
  let results = []

  let i = a:from
  let limit = a:to + 1

  while i < limit
    let m = matchlist(a:data[i], format)[1:4]

    if len(m) != 4
      if index(self.broken_results, a:data[i]) < 0
        call add(self.broken_results, {'after': a:data[i-1], 'res': a:data[i]})
      endif
    else
      call add(results, {'filename': m[0], 'lnum': m[1], 'col': m[2], 'text': m[3]})
    endif
    let i += 1
  endwhile

  return results
endfu

fu! s:expand_escaped_glob(str) abort
  let re_escaped='\%(\\\)\@<!\%(\\\\\)*\zs\\'
  return substitute(a:str, re_escaped . '\*', '*', 'g')
endfu
