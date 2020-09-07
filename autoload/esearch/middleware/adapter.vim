fu! esearch#middleware#adapter#apply(esearch) abort
  call s:set_current_adapter(a:esearch)
  call s:set_parser(a:esearch)

  if type(a:esearch.regex) !=# type('') && !empty(a:esearch._adapter.textobj)
    let a:esearch.regex = a:esearch._adapter.bool2regex[!!a:esearch.regex]
  endif
  if type(a:esearch.case) !=# type('') && !empty(a:esearch._adapter.textobj)
    let a:esearch.case = a:esearch._adapter.bool2case[!!a:esearch.case]
  endif
  if type(a:esearch.textobj) !=# type('') && !empty(a:esearch._adapter.textobj)
    let a:esearch.textobj = a:esearch._adapter.bool2textobj[!!a:esearch.textobj]
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
  let a:esearch._adapter = a:esearch.adapters[a:esearch.adapter]
endfu

fu! s:set_parser(esearch) abort
  if a:esearch.parse_strategy ==# 'lua'
    let a:esearch.parse = esearch#adapter#parse#lua#import()
  else
    let a:esearch.parse = esearch#adapter#parse#viml#import()[a:esearch._adapter.parser]
  endif
endfu
