let g:esearch#middleware#pattern#cache = esearch#cache#lru#new(128)

fu! esearch#middleware#pattern#apply(esearch) abort
  let esearch = extend(a:esearch, {'cmdline': ''}, 'keep')

  if empty(get(esearch, 'pattern'))
    let pattern_type = esearch.regex ==# 'literal' ? 'literal' : 'pcre'
    let esearch.cmdline = esearch#prefill#try(esearch)[pattern_type]
    let esearch = esearch#cmdline#read(esearch)
    if !get(esearch, 'live_exec')
      " TODO handle removing live_update win
      if empty(esearch.cmdline) | throw 'Cancel' | endif
    endif
    let esearch.pattern = s:cached_or_new(esearch.cmdline, esearch)
    let g:esearch.last_pattern = esearch.pattern
  elseif type(esearch.pattern) ==# type('')
    let esearch.pattern = s:cached_or_new(esearch.pattern, esearch)
  endif

  return esearch
endfu

fu! s:cached_or_new(text, esearch) abort
  if g:esearch#middleware#pattern#cache.has(a:text)
    let pattern = g:esearch#middleware#pattern#cache.get(a:text)
  else
    let pattern = esearch#pattern#new(
          \ a:text,
          \ a:esearch.regex,
          \ a:esearch.case,
          \ a:esearch.textobj)
    call g:esearch#middleware#pattern#cache.set(a:text, pattern)
  endif

  return pattern
endfu
