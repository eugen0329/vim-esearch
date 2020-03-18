let esearch#adapter#grep_like#multiple_files_Search_format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

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
      call add(results, {
            \ 'filename': substitute(m[0], b:esearch.cwd_prefix, '', ''),
            \ 'lnum': m[1], 'text': m[2]})
    endif
    let i += 1
  endwhile

  return results
endfu
