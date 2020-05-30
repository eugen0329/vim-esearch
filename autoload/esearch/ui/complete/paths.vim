let s:Filepath = vital#esearch#import('System.Filepath')
let s:List     = vital#esearch#import('Data.List')

fu! esearch#ui#complete#paths#do(cwd, arglead, cmdline, curpos) abort
  let original_cwd = esearch#win#lcd(a:cwd) " as most of builtin functions depend on cwd
  try
    let [current_word, prefix_text] = esearch#ui#complete#base#parse_arglead(a:arglead)

    let already_listed = map(split(a:cmdline, '\s\+'),
          \ 'fnameescape(s:Filepath.relpath(resolve(v:val)))')

    let candidates = []
    for candidate in s:gather_candidates(a:cwd, current_word, already_listed)
      if isdirectory(candidate) | let candidate .= '/' | endif
      call add(candidates, prefix_text . candidate)
    endfor
  finally
    call original_cwd.restore()
  endtry

  return candidates
endfu

fu! s:gather_candidates(cwd, word, already_listed) abort
  let ignorecase = esearch#let#restorable({
        \ '&wildignorecase': 1,
        \ '&fileignorecase': 1})

  let word  = fnameescape(s:Filepath.relpath(resolve(a:word)))

  try
    let candidates = split(globpath(a:cwd, word . '*'), "\n")
  finally
    call ignorecase.restore()
  endtry

  let unused_candidates = []
  for candidate in candidates
    let candidate = fnameescape(s:Filepath.relpath(resolve(candidate)))

    if !s:List.has(a:already_listed, candidate) || candidate ==# a:word
      let unused_candidates += [candidate]
    endif
  endfor

  return unused_candidates
endfu
