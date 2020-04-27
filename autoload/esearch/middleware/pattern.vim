fu! esearch#middleware#pattern#apply(esearch) abort
  let esearch = a:esearch

  let esearch = extend(esearch, {
        \ 'cmdline':    0,
        \ 'visualmode': 0,
        \ 'is_regex':   function('<SID>is_regex'),
        \}, 'keep')

  if empty(get(esearch, 'pattern'))
    let pattern_type = esearch.is_regex() ? 'pcre' : 'literal'
    let esearch.cmdline = esearch#prefill#try(esearch)[pattern_type]
    let esearch = esearch#cmdline#read(esearch)
    if empty(esearch.cmdline) | throw 'Cancel' | endif
    let esearch.pattern = esearch#pattern#new(
          \ esearch.cmdline,
          \ esearch.is_regex(),
          \ esearch.case,
          \ esearch.textobj)
    let g:esearch.last_pattern = esearch.pattern
  else
    if type(esearch.pattern) ==# type('')
      " Preprocess the pattern
      let esearch.pattern = esearch#pattern#new(
            \ esearch.pattern,
            \ esearch.is_regex(),
            \ esearch.case,
            \ esearch.textobj)
    endif
  endif

  return esearch
endfu

fu! s:is_regex() abort dict
  return self.regex !=# 'literal'
endfu
