let s:Filepath = vital#esearch#import('System.Filepath')
let s:List     = vital#esearch#import('Data.List')

fu! esearch#ui#complete#paths#do(arglead, cmdline, curpos) abort
  let [current_word, prefix_text] = esearch#ui#complete#base#parse_arglead(a:arglead)

  let already_listed = map(split(a:cmdline, '\s\+'),
        \ 'fnameescape(s:Filepath.relpath(resolve(v:val)))')

  let candidates = []
  for file in s:gather_candidates(current_word, already_listed)
    let candidate = fnameescape(s:Filepath.relpath(resolve(file)))
    if isdirectory(candidate) | let candidate .= '/' | endif

    call add(candidates, prefix_text . candidate)
  endfor

  return candidates
endfu

fu! s:gather_candidates(word, already_listed) abort
  let ignorecase = esearch#let#restorable({
        \ '&wildignorecase': 1,
        \ '&fileignorecase': 1})
  try
    let candidates = split(globpath(getcwd(), a:word.'*'), "\n")
  finally
    call ignorecase.restore()
  endtry

  let unused_candidates = []
  for candidate in candidates
    if !s:List.has(a:already_listed, candidate)
      let unused_candidates += [candidate]
    endif
  endfor

  return unused_candidates
endfu
