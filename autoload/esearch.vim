fu! esearch#init(...) abort
  call esearch#util#doautocmd('User eseach_init_pre')
  call esearch#config#eager()

  let esearch = extend(copy(get(a:, 1, {})), copy(g:esearch), 'keep')
  let esearch = esearch#middleware#id#apply(esearch)
  let esearch = esearch#middleware#adapter#apply(esearch)
  let esearch = esearch#middleware#cwd#apply(esearch)
  let esearch = esearch#middleware#paths#apply(esearch)
  let esearch = esearch#middleware#nerdtree#apply(esearch)
  let esearch = esearch#middleware#prewarm#apply(esearch)
  let esearch = esearch#middleware#pattern#apply(esearch)
  let esearch = esearch#middleware#remember#apply(esearch)
  let esearch = esearch#middleware#exec#apply(esearch)
  let esearch = esearch#middleware#title#apply(esearch)

  call esearch#out#{esearch.out}#init(esearch)
endfu

fu! esearch#_mappings() abort
  if !exists('s:mappings')
    let s:mappings = [
          \ {'lhs': '<leader>ff', 'rhs': '<Plug>(esearch)', 'default': 1},
          \ {'lhs': '<leader>fw', 'rhs': '<Plug>(esearch-word-under-cursor)', 'default': 1},
          \]
  endif
  return s:mappings
endfu

fu! esearch#map(map, plug) abort
  call esearch#mappings#add(esearch#_mappings(), a:map, printf('<Plug>(%s)', a:plug))
endfu

fu! esearch#debounce(...) abort
  return call('esearch#debounce#new', a:000)
endfu

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
