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
  if index(['line', 'char', 'block'], a:type) >= 0
    return esearch#init({'prefill': ['region'], 'region': s:type2region(a:type)})
  else
    return esearch#init({'prefill': ['region'], 'region': s:type2region(a:type)})
  endif
endfu

fu! esearch#opfunc_exec(type) abort
  if index(['line', 'char', 'block'], a:type) >= 0
    return esearch#init({'pattern': esearch#util#region_text("'[", "']", a:type)})
  else
    return esearch#init({'pattern': esearch#util#region_text("'<", "'>", a:type)})
  endif
endfu

fu! s:type2region(type) abort
  if index(['v', 'V', "\<C-v>"], a:type)
    return ["'<", "'>", a:type]
  elseif a:type ==# 'line'
    return ["'[", "']", a:type]
  else
    return ['`[', '`]', a:type]
  endif
endfu

fu! esearch#map(lhs, rhs) abort
  let g:esearch = get(g:, 'esearch', {})
  let g:esearch = extend(g:esearch, {'pending_deprecations': []}, 'keep')
  let g:esearch.pending_deprecations += ['esearch#map, use map {keys} <Plug>(esearch)']

  if a:rhs ==# 'esearch'
    call esearch#map#set({'lhs': a:lhs, 'rhs': '<Plug>(esearch)', 'mode': ' ', 'silent': 1})
  elseif a:rhs ==# 'esearch-word-under-cursor'
    call esearch#map#set({'lhs': a:lhs, 'rhs': '<Plug>(esearch-operator)iw', 'mode': ' ', 'silent': 1})
  endif
endfu

fu! esearch#debounce(...) abort
  return call('esearch#debounce#new', a:000)
endfu

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
