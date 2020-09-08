let g:esearch#middleware#pattern#cache = esearch#cache#lru#new(128)

fu! esearch#middleware#pattern#apply(esearch) abort
  let esearch = extend(a:esearch, {'cmdline': ''}, 'keep')

  if empty(get(esearch, 'pattern'))
    let esearch.pattern = esearch#prefill#try(esearch)
    call esearch.pattern.adapt(esearch._adapter)
    let esearch = esearch#cmdline#read(esearch)
    if empty(esearch.pattern.peek().str) | call s:cancel(esearch) | endif

    call esearch.pattern.splice(esearch)
  else
    if type(esearch.pattern) ==# type('')
      let esearch.pattern = s:cached_or_new(esearch.pattern, esearch)
    endif
    call esearch.pattern.adapt(esearch._adapter)
    call esearch.pattern.splice(esearch)
    " avoid live_update if the pattern is present unless is it's a part of live_exec flow
    let esearch.live_update = esearch.live_exec
  endif
  let esearch.last_pattern = esearch.pattern

  return esearch
endfu

fu! s:cancel(esearch) abort
  if a:esearch.live_update && bufexists(a:esearch.live_update_bufnr)
    exe a:esearch.live_update_bufnr 'bwipeout'
  endif
  let a:esearch.live_update_bufnr = -1
  throw 'Cancel'
endfu

fu! s:cached_or_new(text, esearch) abort
  if g:esearch#middleware#pattern#cache.has(a:text)
    let pattern = g:esearch#middleware#pattern#cache.get(a:text)
  else
    let pattern = esearch#pattern#new(a:esearch._adapter, a:text)
    call g:esearch#middleware#pattern#cache.set(a:text, pattern)
  endif

  return pattern
endfu
