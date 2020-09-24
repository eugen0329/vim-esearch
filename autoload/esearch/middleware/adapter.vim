let s:modes = ['case', 'regex', 'textobj']

fu! esearch#middleware#adapter#apply(esearch) abort
  call s:set_current_adapter(a:esearch)
  call s:set_parser(a:esearch)

  for mode in s:modes
    if !empty(a:esearch._adapter[mode])
      if type(a:esearch[mode]) !=# type('')
        let a:esearch[mode] = a:esearch._adapter['bool2'.mode][!!a:esearch[mode]]
      elseif !has_key(a:esearch._adapter[mode], a:esearch[mode])
        let a:esearch[mode] = a:esearch._adapter['bool2'.mode][0]
      endif
    endif
  endfor

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
