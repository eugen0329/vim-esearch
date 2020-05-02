fu! esearch#init(...) abort
  call esearch#util#doautocmd('User eseach_init_pre')
  call esearch#config#eager()

  let esearch = extend(copy(get(a:, 1, {})), copy(g:esearch), 'keep')
  try
    for Middleware in esearch.middleware
      let esearch = Middleware(esearch)
    endfor
  catch /^Cancel$/
    return
  endtry

  call esearch#out#{esearch.out}#init(esearch)
endfu

fu! esearch#opfunc_prefill(type) abort
  return esearch#init({'prefill': ['region'], 'region': esearch#util#type2region(a:type)})
endfu

fu! esearch#opfunc_exec(type) abort
  return esearch#init({'pattern': esearch#util#region_text(esearch#util#type2region(a:type))})
endfu

" DEPRECATED
fu! esearch#map(lhs, rhs) abort
  let g:esearch = get(g:, 'esearch', {})
  let g:esearch = extend(g:esearch, {'pending_deprecations': []}, 'keep')

  if a:rhs ==# 'esearch'
    call esearch#map#define({'lhs': a:lhs, 'rhs': '<Plug>(esearch)', 'mode': ' ', 'silent': 1})
    let g:esearch.pending_deprecations += ['esearch#map, use map {keys} <Plug>(esearch)']
  elseif a:rhs ==# 'esearch-word-under-cursor'
    let g:esearch.pending_deprecations += ['esearch#map, use map {keys} <Plug>(esearch-operator){textobject}']
    call esearch#map#define({'lhs': a:lhs, 'rhs': '<Plug>(esearch-operator)iw', 'mode': ' ', 'silent': 1})
  else
    let g:esearch.pending_deprecations += ['esearch#map, see :help esearch-mappings']
  endif
endfu

fu! esearch#debounce(...) abort
  return call('esearch#debounce#new', a:000)
endfu

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
