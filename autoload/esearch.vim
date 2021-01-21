fu! esearch#init(...) abort
  call esearch#util#doautocmd('User eseach_init_pre')
  call esearch#config#eager()

  let esearch = extend(extend(copy(g:esearch), {'remember': 0}), copy(get(a:, 1, {})))
  try
    for l:Middleware in esearch.middleware.list
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

fu! esearch#exec(...) abort
  return esearch#operator#expr('esearch#exec_op', get(a:, 1, {}))
endfu

fu! esearch#prefill_op(wise) abort
  call esearch#init(extend({'prefill': ['region'], 'region': a:wise}, get(esearch#operator#args(), 0, {})))
endfu

fu! esearch#exec_op(wise) abort
  call esearch#init(extend({'prefill': ['region'], 'region': a:wise, 'force_exec': 1}, get(esearch#operator#args(), 0, {})))
endfu

" DEPRECATED
fu! esearch#map(lhs, rhs) abort
  let g:esearch = get(g:, 'esearch', {})
  let g:esearch = extend(g:esearch, {'pending_warnings': []}, 'keep')

  if a:rhs ==# 'esearch'
    call esearch#util#deprecate('esearch#map, use map {keys} <plug>(esearch)')
    call esearch#keymap#set('n', a:lhs, '<plug>(esearch)', {'silent': 1})
  elseif a:rhs ==# 'esearch-word-under-cursor'
    call esearch#util#deprecate("esearch#map with 'esearch-word-under-cursor', use map {keys} <plug>(operator-esearch-prefill)iw")
    call esearch#keymap#set('n', a:lhs, '<plug>(esearch-operator)iw', {'silent': 1})
  else
    call esearch#util#deprecate('esearch#map, see :help esearch-mappings')
  endif
endfu

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
