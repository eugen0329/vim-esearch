fu! esearch#init(...) abort
  call esearch#util#doautocmd('User eseach_init_pre')

  if esearch#opts#init_lazy_global_config() != 0
    return 0
  endif

  let esearch = s:new(get(a:000, 0, {}))
  let g:esearch.last_id += 1
  let esearch.id = g:esearch.last_id

  " Must be called before the commandline start to do prewarming while user
  " inputting the string
  call esearch#ftdetect#async_prewarm_cache()

  if has_key(esearch, 'pattern')
    if type(esearch.pattern) ==# type('')
      " Preprocess the pattern
      let esearch.pattern = esearch#pattern#new(
            \ esearch.pattern,
            \ esearch.is_regex(),
            \ esearch.case,
            \ esearch.textobj)
    endif
  else
    let pattern_type = esearch.is_regex() ? 'pcre' : 'literal'
    let esearch.cmdline = esearch#source#pick_exp(esearch.use, esearch)[pattern_type]
    let esearch = esearch#cmdline#read(esearch)
    if empty(esearch.cmdline) | return | endif
    let esearch.pattern = esearch#pattern#new(
          \ esearch.cmdline,
          \ esearch.is_regex(),
          \ esearch.case,
          \ esearch.textobj)
  endif

  " TODO add 'remember' option to handle memoization below
  let g:esearch.last_pattern    = esearch.pattern
  let g:esearch.case            = esearch.case
  let g:esearch.textobj         = esearch.textobj
  let g:esearch.regex           = esearch.regex
  let g:esearch.before          = esearch.before
  let g:esearch.after           = esearch.after
  let g:esearch.context         = esearch.context
  let g:esearch.paths           = esearch.paths
  let g:esearch.metadata        = esearch.metadata
  let g:esearch.adapters        = esearch.adapters
  let g:esearch.current_adapter = esearch.current_adapter

  let Escape = function('esearch#backend#'.esearch.backend.'#escape_cmd')
  let pattern = esearch.pattern.str()
  let command = esearch.current_adapter.command(esearch, pattern, Escape)
  let esearch.request = esearch#backend#{esearch.backend}#init(
        \ esearch.cwd, esearch.adapter, command)
  call esearch#backend#{esearch.backend}#run(esearch.request)
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
        \ 'cmdline':    0,
        \ 'visualmode': 0,
        \ 'is_regex':   function('<SID>is_regex'),
        \}, 'keep')

  if has_key(esearch.adapters, esearch.adapter)
    call extend(esearch.adapters[esearch.adapter], esearch#adapter#{esearch.adapter}#new(), 'keep')
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
  if has_key(esearch, 'word')
    " TODO warn deprecated
    let esearch.textobj = esearch.current_adapter.spec._textobj[!!esearch.word]
  endif
  if type(esearch.textobj) !=# type('')
    let esearch.textobj = esearch.current_adapter.spec._textobj[!!esearch.textobj]
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

fu! s:title(esearch, pattern) abort
  let format = s:title_format(a:esearch)
  let modifiers  = get(a:esearch.current_adapter.spec.case, a:esearch.case, {'icon': ''}).icon
  let regex_icon = get(a:esearch.current_adapter.spec.regex, a:esearch.regex, {'icon': ''}).icon
  if regex_icon !=# 'r'
    let modifiers .=regex_icon
  endif
  let modifiers .= get(a:esearch.current_adapter.spec.textobj, a:esearch.textobj, {'icon': ''}).icon
  return printf(format, substitute(a:pattern, '%', '%%', 'g'), modifiers)
endfu

" Results bufname format builder
fu! s:title_format(esearch) abort
  if a:esearch.is_regex()
    if g:esearch#has#unicode
      return printf('Search %s%%s%s%%s', g:esearch#unicode#slash, g:esearch#unicode#slash)
    else
      return "Search r'%s'%s"
    endif
  else
    if g:esearch#has#unicode
      return printf('Search %s%%s%s%%s', g:esearch#unicode#quote_left, g:esearch#unicode#quote_right)
    else
      return 'Search <%s>%s'
    endif
  endif
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

fu! esearch#debounce(...) abort
  return call('esearch#debounce#new', a:000)
endfu

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
