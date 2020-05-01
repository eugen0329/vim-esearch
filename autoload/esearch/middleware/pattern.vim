let g:esearch#middleware#pattern#cache = esearch#cache#lru#new(128)

fu! esearch#middleware#pattern#apply(esearch) abort
  let esearch = a:esearch

  let esearch = extend(esearch, {
        \ 'cmdline': '',
        \ 'is_regex':   function('<SID>is_regex'),
        \}, 'keep')

  if empty(get(esearch, 'pattern'))
    let pattern_type = esearch.is_regex() ? 'pcre' : 'literal'
    let esearch.cmdline = esearch#prefill#try(esearch)[pattern_type]
    let esearch = esearch#cmdline#read(esearch)
    if empty(esearch.cmdline) | throw 'Cancel' | endif
    let esearch.pattern = s:pattern(esearch.cmdline, esearch)
    let g:esearch.last_pattern = esearch.pattern
  else
    if type(esearch.pattern) ==# type('') " Preprocess
      let esearch.pattern = s:pattern(esearch.pattern, esearch)
    endif
  endif

  return esearch
endfu

fu! s:is_regex() abort dict
  return self.regex !=# 'literal'
endfu

fu! s:pattern(text, esearch) abort
  if g:esearch#middleware#pattern#cache.has(a:text)
    let pattern = g:esearch#middleware#pattern#cache.get(a:text)
  else
    let pattern = esearch#pattern#new(
          \ a:text,
          \ a:esearch.is_regex(),
          \ a:esearch.case,
          \ a:esearch.textobj)
    call g:esearch#middleware#pattern#cache.set(a:text, pattern)
  endif

  return pattern
endfu
