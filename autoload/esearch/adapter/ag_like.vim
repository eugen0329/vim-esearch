let esearch#adapter#ag_like#format = '^\(.\{-}\)\:\(\d\{-}\)\:\(.\{-}\)$'

fu! esearch#adapter#ag_like#joined_paths(esearch) abort
  if empty(a:esearch.paths)
    let joined_paths = a:esearch.cwd
  else
    let joined_paths = esearch#shell#fnamesescape_and_join(a:esearch.paths, a:esearch.metadata)
  endif

  return joined_paths
endfu

fu! esearch#adapter#ag_like#set_results_parser(esearch) abort
  if g:esearch#has#getqflist_lines
    let a:esearch.parse =
          \ function('esearch#adapter#ag_like#parse_with_getqflist_lines')
  else
    let a:esearch.parse = function('esearch#adapter#ag_like#parse')
    let a:esearch.format = g:esearch#adapter#ag_like#format
  endif

  let a:esearch.expand_filename = function('esearch#adapter#ag_like#expand_filename')
endfu

fu! esearch#adapter#ag_like#expand_filename(filename) abort dict
  return a:filename
endfu

fu! esearch#adapter#ag_like#parse_with_getqflist_lines(data, from, to) abort dict
  if empty(a:data) | return [] | endif

  let items = getqflist({'lines': a:data[a:from : a:to], 'efm': '%f:%l:%m'}).items
  try
    " changing cwd is required as bufname() has side effects
    let saved_cwd = getcwd()
    if !empty(b:esearch.cwd)
      exe 'lcd' b:esearch.cwd
    endif
    let g:items = items
    for i in items
      let i['filename'] = bufname(i['bufnr'])
    endfor
  finally
    if !empty(saved_cwd)
      exe 'lcd' saved_cwd
    endif
  endtry
  return items
endfu

fu! esearch#adapter#ag_like#parse(data, from, to) abort dict
  let format = self.format
  let results = []

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

fu! s:expand_escaped_glob(str) abort
  let re_escaped='\%(\\\)\@<!\%(\\\\\)*\zs\\'
  return substitute(a:str, re_escaped . '\*', '*', 'g')
endfu
