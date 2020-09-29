let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#prefill#try(esearch) abort
  for Prefiller in a:esearch.prefill
    if type(Prefiller) == s:t_func
      let pattern = Prefiller(a:esearch)
    else
      try
        let pattern = esearch#prefill#{Prefiller}(a:esearch)
      catch /^Vim(function):E127/
        " TODO write options validation middleware
        continue
      endtry
    endif

    if !empty(pattern)
      if type(pattern) == s:t_string
        return esearch#pattern#new(a:esearch._adapter, pattern)
      else
        return pattern
      endif
    endif
  endfor

  return esearch#pattern#new(a:esearch._adapter, '')
endfu

fu! esearch#prefill#region(esearch) abort
  if !empty(get(a:esearch, 'region'))
    let text = esearch#operator#text(a:esearch.region)
    return esearch#pattern#new(a:esearch._adapter, text)
  endif
endfu

fu! esearch#prefill#visual(esearch) abort
  " DEPRECATED
endfu

fu! esearch#prefill#hlsearch(esearch) abort
  if !get(v:, 'hlsearch') | return | endif

  let str = getreg('/')
  if empty(str) | return | endif

  if a:esearch.regex is# 'literal' || empty(a:esearch._adapter.regex)
    let text = esearch#pattern#vim2literal#convert(str)
  else
    let text = esearch#pattern#vim2pcre#convert(str)
  endif

  return esearch#pattern#new(a:esearch._adapter, text)
endfu

fu! esearch#prefill#last(_esearch) abort
  return deepcopy(get(g:esearch, 'last_pattern'))
endfu

fu! esearch#prefill#current(_esearch) abort
  if exists('b:esearch')
    return deepcopy(get(b:esearch, 'pattern'))
  endif
endfu

fu! esearch#prefill#cword(esearch) abort
  let cword = expand('<cword>')
  if !empty(cword)
    return esearch#pattern#new(a:esearch._adapter, cword)
  endif
endfu

fu! esearch#prefill#clipboard(esearch) abort
  return esearch#pattern#new(a:esearch._adapter, getreg(esearch#util#clipboard_reg()))
endfu
