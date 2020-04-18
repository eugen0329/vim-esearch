let s:Filepath = vital#esearch#import('System.Filepath')
let s:List     = vital#esearch#import('Data.List')

fu! esearch#ui#complete#paths#do(arglead, cmdline, curpos) abort
  let [current_word, prefix_text] = s:word_with_prefix(a:arglead)
  let g:asd = [current_word, prefix_text]

  let already_listed = map(split(a:cmdline, '\s\+'),
        \ 'fnameescape(s:Filepath.relpath(resolve(v:val)))')

  let candidates = []
  for file in s:gather_candidates(current_word)
    let candidate = fnameescape(s:Filepath.relpath(resolve(file)))
    if isdirectory(candidate) | let candidate .= '/' | endif

    if !s:List.has(already_listed, candidate)
      call add(candidates, prefix_text . candidate)
    endif
  endfor
  return candidates
endfu

fu! s:gather_candidates(word) abort
  let ignorecase = esearch#let#restorable({
        \ '&wildignorecase': 1,
        \ '&fileignorecase': 1})
  try
    return split(globpath(getcwd(), a:word.'*'), "\n")
  finally
    call ignorecase.restore()
  endtry
endfu

fu! s:word_with_prefix(arglead) abort
  let leading_words = split(a:arglead, '\s\+')
  if a:arglead =~# '\s$' || empty(leading_words)
    return ['' , a:arglead]
  endif

  let current_word = leading_words[-1]
  if strchars(a:arglead) == strchars(current_word)
    return [current_word, '']
  endif

  let prefix_text = a:arglead[: strchars(a:arglead) - strchars(current_word) - 1]
  if prefix_text !~# '\s$'
    let prefix_text .= ' '
  endif

  return [current_word, prefix_text]
endfu
