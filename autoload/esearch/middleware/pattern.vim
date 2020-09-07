let g:esearch#middleware#pattern#cache = esearch#cache#lru#new(128)

fu! esearch#middleware#pattern#apply(esearch) abort
  let esearch = extend(a:esearch, {'cmdline': ''}, 'keep')

  if empty(get(esearch, 'pattern'))
    let esearch.pattern = esearch#prefill#try(esearch)
    " PP
    let esearch = esearch#cmdline#read(esearch)
    if empty(esearch.pattern.curr().str) | call s:cancel(esearch) | endif
    call esearch.pattern.convert(esearch)
    " let esearch.pattern = s:cached_or_new(esearch.cmdline, esearch)
    let g:esearch.last_pattern = esearch.pattern
  else
    " if type(esearch.pattern) ==# type('')
      " let esearch.pattern = s:cached_or_new(esearch.pattern, esearch)
    " endif
    " avoid live_update if the pattern is present unless is it's a part of live_exec flow
    call esearch.pattern.convert(esearch)
    let esearch.live_update = esearch.live_exec
  endif

  return esearch
endfu

fu! s:cancel(esearch) abort
  if a:esearch.live_update && a:esearch.live_update_bufnr >= 0
    exe a:esearch.live_update_bufnr 'bwipeout'
    let a:esearch.live_update_bufnr = -1
  endif
  throw 'Cancel'
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
