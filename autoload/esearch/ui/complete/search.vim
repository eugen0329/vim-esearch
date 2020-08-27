" borrowed from oblique and incsearch
fu! esearch#ui#complete#search#do(arglead, ...) abort
  let equal             = []
  let partially_matched = []
  let spell_suggested   = []
  let fuzzy_matched     = []
  let start_with        = []

  let fuzzy_re = s:fuzzy_re(a:arglead)
  let spell_re = s:spell_re(a:arglead)

  let word_len = strlen(a:arglead)
  for word in s:buffer_words(word_len)
    if word == a:arglead
      call add(equal, word)
      continue
    endif

    let substr_index = stridx(word, a:arglead)
    if substr_index == 0
      call add(start_with, word)
    elseif substr_index >= 0
      call add(partially_matched, word)
    elseif word_len > 2
      if word =~ spell_re
        call add(spell_suggested, word)
      elseif word =~ fuzzy_re
        call add(fuzzy_matched, word)
      endif
    endif
  endfor

  call sort(fuzzy_matched,     'esearch#util#compare_len')
  call sort(spell_suggested,   'esearch#util#compare_len')
  call sort(equal,             'esearch#util#compare_len')
  call sort(partially_matched, 'esearch#util#compare_len')
  return [a:arglead] + equal + start_with + partially_matched + spell_suggested + fuzzy_matched
endfu

fu! s:spell_re(arglead) abort
  let spell_re = a:arglead
  let spell = esearch#let#restorable({'&spellsuggest': 1, '&spell': 1})
  try
    return substitute(spell_re, '\h\k*', '\=s:spell_suggestions(submatch(0))', 'g')
  finally
    call spell.restore()
  endtry
endfu

fu! s:spell_suggestions(word) abort
  return printf('\m\(%s\)', join(spellsuggest(a:word, 10), '\|'))
endfu

fu! s:fuzzy_re(arglead) abort
  let chars = map(split(a:arglead, '.\zs'), 'escape(v:val, "\\[]^$.*")')
  let fuzzy_re = join(
        \ extend(map(chars[0 : -2], "v:val . '[^' .v:val. ']\\{-}'"),
        \ chars[-1:-1]), '')
endfu

fu! s:buffer_words(min_len) abort
  let words = esearch#util#buff_words()
  if a:min_len < 4
    call filter(words, 'a:min_len <= strlen(v:val)')
  endif
  return words
endfu
