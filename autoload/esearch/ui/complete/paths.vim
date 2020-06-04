let s:Filepath = vital#esearch#import('System.Filepath')
let s:List     = vital#esearch#import('Data.List')

fu! esearch#ui#complete#paths#do(cwd, arglead, cmdline, _curpos) abort
  let original_cwd = esearch#win#lcd(a:cwd) " as most of builtin functions depend on cwd
  try
    if g:esearch#has#posix_shell
      return s:posix_candidates(a:cwd, a:arglead, a:cmdline)
    else
      return s:windows_candidates(a:cwd, a:arglead, a:cmdline)
    endif
  catch
    echomsg v:exception
  finally
    call original_cwd.restore()
  endtry
endfu

fu! s:windows_candidates(cwd, arglead, cmdline) abort
  let words = split(a:cmdline)
  let [word, prefix] = esearch#ui#complete#base#word_and_prefix(a:arglead)
  let word = s:Filepath.relpath(word)
  let candidates = map(s:glob(a:cwd, word), 'shellescape(s:minimize(v:val))')
  return map(filter(candidates, 'stridx(a:cmdline, v:val) == -1'), 'prefix . v:val')
endfu

fu! s:posix_candidates(cwd, arglead, cmdline) abort
  let [word, prefix_text] = s:parse_posix_argled(a:arglead)
  let [already_listed, _] = esearch#shell#split(a:cmdline)
  let Escape = function('fnameescape')
  let already_listed = map(already_listed, 'Escape(s:minimize(v:val.str))')
  let candidates = []
  let separator = s:Filepath.separator()

  for candidate in s:gather_posix_candidates(a:cwd, word, already_listed, Escape)
    if isdirectory(candidate) | let candidate .= separator | endif
    call add(candidates, prefix_text . candidate)
  endfor

  return candidates
endfu

fu! s:gather_posix_candidates(cwd, word, already_listed, Escape) abort
  let candidates = []
  let word = s:Filepath.relpath(a:word)
  for candidate in s:glob(a:cwd, word)
    let candidate = a:Escape(s:minimize(candidate))
    if !s:List.has(a:already_listed, candidate)
      let candidates += [candidate]
    endif
  endfor

  if word =~# g:esearch#shell#metachars_pattern
    " keep the current word if includes metachars
    let candidates = [word] + candidates
  endif

  return candidates
endfu

fu! s:minimize(arg) abort
  return s:Filepath.relpath(s:Filepath.remove_last_separator(simplify(a:arg)))
endfu

fu! s:parse_posix_argled(arglead) abort
  let [leading_words, _] = esearch#shell#split(a:arglead)
  " no current word
  if empty(leading_words) || leading_words[-1].end < strchars(a:arglead)
    return ['' , a:arglead]
  endif

  let word = leading_words[-1]
  let prefix_text = len(leading_words) == 1 ? '' : a:arglead[:word.begin - 1]
  return [word.str, prefix_text]
endfu

fu! s:glob(cwd, word) abort
  let ignorecase = esearch#let#restorable({
        \ '&wildignorecase': 1,
        \ '&fileignorecase': 1})
  try
    return split(globpath(a:cwd, a:word . (a:word =~# '\*$' ? '' : '*')), "\n")
  finally
    call ignorecase.restore()
  endtry
endfu
