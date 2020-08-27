let s:List = vital#esearch#import('Data.List')

fu! esearch#ui#complete#filetypes#do(filetypes, arglead, cmdline, curpos) abort
  let [word, prefix] = esearch#ui#complete#base#word_and_prefix(a:arglead)
  let already_listed = split(a:cmdline)
  let candidates = s:gather_candidates(a:filetypes, word, already_listed)
  return map(candidates, 'prefix . v:val')
endfu

fu! s:gather_candidates(filetypes, word, already_listed) abort
  " remove incorrect and non-glob chars and match case insensitively
  let pattern = '\c' . substitute(a:word, '[^0-9A-Za-z_\-*?[\]]', '', 'g')
  if pattern =~# '[*?[\]]'
    let pattern = glob2regpat(pattern)
  endif

  let candidates = filter(copy(a:filetypes),
        \ '(v:val ==# a:word || !s:List.has(a:already_listed, v:val)) && v:val =~? pattern')
  return s:List.sort(candidates, '(len(a:a) - len(a:b))')
endfu
