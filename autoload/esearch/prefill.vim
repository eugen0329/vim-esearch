let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#prefill#try(esearch) abort
  let select = a:esearch.select_prefilled
  if has_key(a:esearch, 'region')
    let l:RegionGetter = function('esearch#operator#text', [a:esearch.region])
  else
    let l:RegionGetter = function('<SID>get_empty_string')
  endif

  for l:Prefiller in a:esearch.prefill
    if type(Prefiller) == s:t_func
      let pattern = Prefiller(RegionGetter, a:esearch)
    else
      try
        let pattern = esearch#prefill#{Prefiller}(RegionGetter, a:esearch)
      catch /^Vim(function):E127/
        " TODO write options validation middleware
        continue
      endtry
    endif

    if !empty(pattern)
      if type(pattern) == s:t_string
        let select = strtrans(pattern) ==# pattern
        return [esearch#pattern#new(a:esearch._adapter, pattern), select]
      else
        return [pattern, select]
      endif
    endif
  endfor

  return [esearch#pattern#new(a:esearch._adapter, ''), select]
endfu

fu! esearch#prefill#region(get, esearch) abort
  if !empty(get(a:esearch, 'region'))
    return esearch#pattern#new(a:esearch._adapter, a:get())
  endif
endfu

fu! esearch#prefill#visual(_, esearch) abort
  " DEPRECATED
endfu

fu! esearch#prefill#hlsearch(_, esearch) abort
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

fu! esearch#prefill#last(_, _esearch) abort
  return deepcopy(get(g:esearch, 'last_pattern'))
endfu

fu! esearch#prefill#current(_, _esearch) abort
  if exists('b:esearch')
    return deepcopy(get(b:esearch, 'pattern'))
  endif
endfu

fu! esearch#prefill#cword(_, esearch) abort
  let cword = expand('<cword>')
  if !empty(cword)
    return esearch#pattern#new(a:esearch._adapter, cword)
  endif
endfu

fu! esearch#prefill#clipboard(_, esearch) abort
  return esearch#pattern#new(a:esearch._adapter, getreg(esearch#util#clipboard_reg()))
endfu

fu! s:get_empty_string() abort
  return ''
endfu
