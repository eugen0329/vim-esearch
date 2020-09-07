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
        return esearch#pattern#set(pattern)
      else
        return pattern
      endif
    endif
  endfor

  return esearch#pattern#set(a:esearch._adapter.patterns, '')
endfu

fu! esearch#prefill#region(esearch) abort
  if !empty(get(a:esearch, 'region'))
    let text = esearch#util#region_text(a:esearch.region)
    return esearch#pattern#set(a:esearch._adapter.patterns, text)
  endif
endfu

fu! esearch#prefill#visual(esearch) abort
  " DEPRECATED
endfu

fu! esearch#prefill#hlsearch(esearch) abort
  if !get(v:, 'hlsearch') | return | endif

  let str = getreg('/')
  if empty(str) | return | endif

  if esearch.regex
    return esearch#pattern#set(a:esearch._adapter.patterns, esearch#pattern#vim2pcre#convert(str))
  else
    return esearch#pattern#set(a:esearch._adapter.patterns, esearch#pattern#vim2literal#convert(str))
  endif
endfu

fu! esearch#prefill#last(_esearch) abort
  return get(g:esearch, 'last_pattern')
endfu

fu! esearch#prefill#current(_esearch) abort
  if exists('b:esearch') | return get(b:esearch, 'pattern') | endif
endfu

fu! esearch#prefill#cword(_esearch) abort
  let cword = expand('<cword>')
  if !empty(cword)
    return esearch#pattern#set(a:esearch._adapter.patterns, cword)
  endif
endfu

fu! esearch#prefill#clipboard(_esearch) abort
  let clipboards = split(&clipboard, ',')
  if index(clipboards, 'unnamedplus') >= 0
    let register = '+'
  elseif index(clipboards, 'unnamed') >= 0
    let register = '*'
  else
    let register = '"'
  endif
  return esearch#pattern#set(a:esearch._adapter.patterns, getreg(register))
endfu
