fu! esearch#completion#complete_files(cwd, A,L,P) abort
  let cwd = a:cwd
  " TODO test with comma in cwd
  let candidates = []
  for file in split(globpath(getcwd(), a:A.'*'), "\n")
    let candidate = substitute(file, '^'. getcwd().'/', '', 'g')
    if isdirectory(candidate)
      let candidate .= '/'
    endif
    call add(candidates, fnameescape(candidate))
  endfor

  return candidates
endfu

" borrowed from oblique and incsearch
fu! esearch#completion#buffer_words(A, ...) abort
  let chars = map(split(a:A, '.\zs'), 'escape(v:val, "\\[]^$.*")')
  let fuzzy_pat = join(
        \ extend(map(chars[0 : -2], "v:val . '[^' .v:val. ']\\{-}'"),
        \ chars[-1:-1]), '')

  let spell_pat = a:A
  let spell_save = &spell
  let &spell = 1
  try
    let spell_pat = substitute(spell_pat, '\k\+', '\=s:spell_suggests(submatch(0))', 'g')
  finally
    let &spell = spell_save
  endtry

  " exact, part, spell suggest, fuzzy, begins with
  let e = []
  let p = []
  let s = []
  let f = []
  let b = []

  let words = esearch#util#buff_words()
  " because of less typos in small words
  let word_len = strlen(a:A)
  if word_len < 4
    call filter(words, 'word_len <= strlen(v:val)')
  endif

  for w in words
    if w == a:A
      call add(e, w)
    elseif w =~ '^'.a:A
      call add(b, w)
    elseif w =~ a:A
      call add(p, w)
    elseif word_len > 2 && w =~ spell_pat
      call add(s, w)
    elseif word_len > 2 && w =~ fuzzy_pat
      call add(f, w)
    endif
  endfor

  call sort(f, 'esearch#util#compare_len')
  call sort(s, 'esearch#util#compare_len')
  call sort(e, 'esearch#util#compare_len')
  call sort(p, 'esearch#util#compare_len')
  return e + b + p + s + f
endfu

fu! s:spell_suggests(word) abort
  return printf('\m\(%s\)', join(spellsuggest(a:word, 10), '\|'))
endfu
