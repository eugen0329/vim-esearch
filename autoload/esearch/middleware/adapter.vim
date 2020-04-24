fu! esearch#middleware#adapter#apply(esearch) abort
  call s:set_current_adapter(a:esearch)
  call s:set_parser(a:esearch)

  if type(a:esearch.regex) !=# type('')
    let a:esearch.regex = a:esearch.current_adapter.spec.bool2regex[!!a:esearch.regex]
  endif
  if type(a:esearch.case) !=# type('')
    let a:esearch.case = a:esearch.current_adapter.spec.bool2case[!!a:esearch.case]
  endif
  if has_key(a:esearch, 'word')
    " TODO warn deprecated
    let a:esearch.textobj = a:esearch.current_adapter.spec.bool2textobj[!!a:esearch.word]
  endif
  if type(a:esearch.textobj) !=# type('')
    let a:esearch.textobj = a:esearch.current_adapter.spec.bool2textobj[!!a:esearch.textobj]
  endif

  return a:esearch
endfu

fu! s:set_current_adapter(esearch) abort
  if has_key(a:esearch.adapters, a:esearch.adapter)
    call extend(a:esearch.adapters[a:esearch.adapter],
          \ esearch#adapter#{a:esearch.adapter}#new(), 'keep')
  else
    let a:esearch.adapters[a:esearch.adapter] =
          \ esearch#adapter#{a:esearch.adapter}#new()
  endif
  let a:esearch.current_adapter = a:esearch.adapters[a:esearch.adapter]
endfu

fu! s:set_parser(esearch) abort
  if a:esearch.parse_strategy ==# 'lua'
    let a:esearch.parse = esearch#adapter#parse#lua#funcref()
  else
    let a:esearch.parse = esearch#adapter#parse#viml#funcref()
  endif
endfu
