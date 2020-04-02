fu! esearch#init(...) abort
  silent doau User eseach_init_pre

  if s:init_lazy_global_config() != 0
    return 0
  endif

  let esearch = s:new(a:0 ? a:1 : {})
  let g:esearch.last_id += 1
  let esearch.id = g:esearch.last_id

  call esearch#ftdetect#async_prewarm_cache()

  if has_key(esearch, 'exp')
    let esearch.exp = esearch#regex#new(esearch.exp)
  else
    let esearch.exp  = esearch#source#pick_exp(esearch.use, esearch)
    let esearch      = esearch#cmdline#read(esearch)
    let esearch.exp  = esearch#regex#finalize(esearch.exp, esearch)
  endif

  let g:esearch.last_search = esearch.exp
  let g:esearch.case        = esearch.case
  let g:esearch.word        = esearch.word
  let g:esearch.regex       = esearch.regex
  let g:esearch.paths       = esearch.paths
  let g:esearch.metadata    = esearch.metadata
  let g:esearch.adapters    = esearch.adapters

  if empty(esearch.exp)
    return 1
  endif

  let Escape = function('esearch#backend#'.esearch.backend.'#escape_cmd')
  let pattern = esearch.pattern()
  " let command = esearch#adapter#{esearch.adapter}#cmd(esearch, pattern, Escape)
  let command = esearch.current_adapter.command(esearch, pattern, Escape)
  let esearch.request = esearch#backend#{esearch.backend}#init(
        \ esearch.cwd, esearch.adapter, command)
  let esearch.parse = esearch#adapter#parse#funcref()

  let esearch.title = s:title(esearch, pattern)
  call esearch#out#{esearch.out}#init(esearch)
endfu

fu! s:new(esearch) abort
  let esearch = extend(copy(a:esearch), copy(g:esearch), 'keep')
  let esearch = extend(esearch, {
        \ 'paths':      [],
        \ 'metadata':   [],
        \ 'glob':       0,
        \ 'adapters':   {},
        \ 'visualmode': 0,
        \ 'is_regex':   function('<SID>is_regex'),
        \ 'pattern':    function('<SID>pattern'),
        \}, 'keep')

  if has_key(esearch.adapters, esearch.adapter)
    call extend(esearch.adapters[esearch.adapter], esearch#adapter#{esearch.adapter}#new())
  else
    let esearch.adapters[esearch.adapter] = esearch#adapter#{esearch.adapter}#new()
  endif
  let esearch.current_adapter = esearch.adapters[esearch.adapter]

  if type(esearch.regex) !=# type('')
    let esearch.regex = esearch.current_adapter.spec._regex[!!esearch.regex]
  endif
  if type(esearch.case) !=# type('')
    let esearch.case = esearch.current_adapter.spec._case[!!esearch.case]
  endif

  if !has_key(esearch, 'cwd')
    let esearch.cwd = esearch#util#find_root(getcwd(), g:esearch.root_markers)
  endif

  if type(get(esearch, 'paths', 0)) ==# type('')
    let [paths, metadata, error] = esearch#shell#split(esearch.paths)
    if !empty(error)
      echo " can't parse paths: " . error
    else
      let [esearch.paths, esearch.metadata] = [paths, metadata]
    endif
  endif

  return esearch
endfu

fu! s:is_regex() abort dict
  return self.regex !=# 'literal'
endfu

fu! s:pattern() abort dict
  return self.is_regex() ? self.exp.pcre : self.exp.literal
endfu

fu! s:title(esearch, pattern) abort
  let format = s:title_format(a:esearch)
  let modifiers = ''
  let modifiers .= a:esearch.case ? 'c' : ''
  let modifiers .= a:esearch.word ? 'w' : ''
  return printf(format, substitute(a:pattern, '%', '%%', 'g'), modifiers)
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
  call esearch#util#add_map(esearch#_mappings(), a:map, printf('<Plug>(%s)', a:plug))
endfu

" Results bufname format builder
fu! s:title_format(esearch) abort
  if a:esearch.regex
    if g:esearch#has#unicode
      " Since we can't use '/' in filenames
      return "Search  \u2215%s\u2215%s"
    else
      return 'Search %%r{%s}%s'
    endif
  else
    return 'Search `%s`%s'
  endif
endfu

fu! s:init_lazy_global_config() abort
  let global_esearch = exists('g:esearch') ? g:esearch : {}

  if type(global_esearch) != type({})
    echohl Error | echo 'Error: g:esearch must be a dict' | echohl None
    return 1
  endif

  if !has_key(global_esearch, 'last_id')
    let global_esearch.last_id = 0
  endif

  if !has_key(global_esearch, '__lazy_loaded')
    let g:esearch = esearch#opts#new(global_esearch)
    if empty(g:esearch) | return 1 | endif
    let g:esearch.__lazy_loaded = 1
  endif

  call esearch#highlight#init()

  return 0
endfu

fu! esearch#debounce(...) abort
  return call('esearch#debounce#new', a:000)
endfu

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
