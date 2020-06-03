let s:List = vital#esearch#import('Data.List')

fu! esearch#ui#complete#filetypes#do(filetypes, arglead, cmdline, curpos) abort
  let [word, prefix] = esearch#ui#complete#base#word_and_prefix(a:arglead)
  let already_listed = split(a:cmdline)
  let candidates = s:gather_candidates(a:filetypes, word, already_listed)
  return esearch#ui#complete#base#filter(candidates, a:cmdline, prefix)
endfu

fu! s:gather_candidates(filetypes, word, already_listed) abort
  if stridx(a:word, '*') >= 0
    let pattern = glob2regpat(a:word)
    let candidates = filter(copy(a:filetypes),
          \ '!s:List.has(a:already_listed, v:val) && v:val =~# pattern')
  else
    let candidates = filter(copy(a:filetypes),
          \ '!s:List.has(a:already_listed, v:val) && stridx(v:val, a:word) >= 0')
  endif

  return s:List.sort(candidates, '(len(a:a) - len(a:b))')
endfu
