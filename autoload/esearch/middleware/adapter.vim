fu! esearch#middleware#adapter#apply(esearch) abort
  call s:set_current_adapter(a:esearch)
  call s:set_parser(a:esearch)

  if !empty(a:esearch._adapter.regex)
    if type(a:esearch.regex) !=# type('')
      let a:esearch.regex = a:esearch._adapter.bool2regex[!!a:esearch.regex]
    elseif !has_key(a:esearch._adapter.regex, a:esearch.regex)
      let a:esearch.regex = a:esearch._adapter.bool2regex[0]
    endif
  endif
  if !empty(a:esearch._adapter.case)
    if type(a:esearch.case) !=# type('') && !empty(a:esearch._adapter.case)
      let a:esearch.case = a:esearch._adapter.bool2case[!!a:esearch.case]
    elseif !has_key(a:esearch._adapter.case, a:esearch.case)
      let a:esearch.case = a:esearch._adapter.bool2case[0]
    endif
  endif
  if !empty(a:esearch._adapter.textobj)
    if type(a:esearch.textobj) !=# type('') && !empty(a:esearch._adapter.textobj)
      let a:esearch.textobj = a:esearch._adapter.bool2textobj[!!a:esearch.textobj]
    elseif !has_key(a:esearch._adapter.textobj, a:esearch.textobj)
      let a:esearch.textobj = a:esearch._adapter.bool2textobj[0]
    endif
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
