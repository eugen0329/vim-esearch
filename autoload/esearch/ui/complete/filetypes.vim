let s:List = vital#esearch#import('Data.List')

fu! esearch#ui#complete#filetypes#do(filetypes, arglead, cmdline, curpos) abort
  let [current_word, prefix_text] = esearch#ui#complete#base#parse_arglead(a:arglead)

  let already_listed = split(a:cmdline, '\s\+')
  return map(s:gather_candidates(a:filetypes, current_word, already_listed), 'prefix_text . v:val')
endfu

fu! s:gather_candidates(filetypes, word, already_listed) abort
  let unused_candidates = []
  for candidate in a:filetypes
    if !s:List.has(a:already_listed, candidate)
      let unused_candidates += [candidate]
    endif
  endfor

  let start_with = filter(copy(unused_candidates), printf('stridx(v:val, %s) >= 0', string(a:word)))
  let start_with = s:List.sort(start_with, '(len(a:a) - len(a:b))')
  return start_with
endfu
