fu! esearch#init(...) abort
  call esearch#util#doautocmd('User eseach_init_pre')
  call esearch#config#eager()

  let esearch = extend(extend(copy(g:esearch), {'remember': 0}), copy(get(a:, 1, {})))
  try
    for Middleware in esearch.middleware
      let esearch = Middleware(esearch)
    endfor
  catch /^Cancel$/
    return
  endtry

  return esearch#out#{esearch.out}#init(esearch)
endfu

fu! esearch#prefill(...) abort
  return esearch#operator#expr('esearch#prefill_op', get(a:, 1, {}))
endfu

fu! esearch#exec(wise) abort
  return esearch#operator#expr('esearch#exec_op', get(a:, 1, {}))
endfu

fu! esearch#prefill_op(wise) abort
  call esearch#init(extend(copy(get(esearch#operator#args(), 0, {})), {'prefill': ['region'], 'region': a:wise}))
endfu

fu! esearch#exec_op(wise) abort
  call esearch#init(extend(copy(get(esearch#operator#args(), 0, {})), {'pattern': esearch#operator#text(a:wise)}))
endfu

" DEPRECATED
fu! esearch#map(lhs, rhs) abort
  let g:esearch = get(g:, 'esearch', {})
  let g:esearch = extend(g:esearch, {'pending_warnings': []}, 'keep')

  if a:rhs ==# 'esearch'
    call esearch#util#deprecate('esearch#map, use map {keys} <Plug>(esearch)')
    call esearch#keymap#set('n', a:lhs, '<Plug>(esearch)', {'silent': 1})
  elseif a:rhs ==# 'esearch-word-under-cursor'
    call esearch#util#deprecate("esearch#map with 'esearch-word-under-cursor', use map {keys} <Plug>(operator-esearch-prefill)iw")
    call esearch#keymap#set('n', a:lhs, '<Plug>(esearch-operator)iw', {'silent': 1})
  else
    call esearch#util#deprecate('esearch#map, see :help esearch-mappings')
  endif
endfu

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
