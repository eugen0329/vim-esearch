let g:esearch#middleware#input#cache = esearch#cache#lru#new(128)

fu! esearch#middleware#input#apply(esearch) abort
  let esearch = extend(a:esearch, {'cmdline': ''}, 'keep')

  if empty(get(esearch, 'pattern'))
    let current_win = esearch#win#stay()
    let [esearch.pattern, esearch.select_prefilled] = esearch#prefill#try(esearch)
    call esearch.pattern.adapt(esearch._adapter)
    if esearch.force_exec
      let esearch.live_update = 0
    else
      let esearch = esearch#cmdline#read(esearch)
    endif

    if empty(esearch.pattern.peek().str) | call s:cancel(esearch, current_win) | endif
  else
    if type(esearch.pattern) ==# type('')
      let esearch.pattern = s:cached_or_new(esearch.pattern, esearch)
    endif
    call esearch.pattern.adapt(esearch._adapter)
    " avoid live_update if the pattern is present unless is it's a part of force_exec flow
    let esearch.live_update = esearch.force_exec
  endif

  return esearch
endfu

fu! s:cancel(esearch, current_win) abort
  if a:esearch.live_update && bufexists(a:esearch.live_update_bufnr)
    exe a:esearch.live_update_bufnr 'bwipeout'
  endif
  let a:esearch.live_update_bufnr = -1
  call a:current_win.restore()

  throw 'Cancel'
endfu

fu! s:cached_or_new(text, esearch) abort
  if g:esearch#middleware#input#cache.has(a:text)
    let pattern = g:esearch#middleware#input#cache.get(a:text)
  else
    let pattern = esearch#pattern#new(a:esearch._adapter, a:text)
    call g:esearch#middleware#input#cache.set(a:text, pattern)
  endif

  return pattern
endfu

