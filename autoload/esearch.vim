fu! esearch#init(...) abort
  if s:init_lazy_global_config() != 0
    return 1
  endif

  let esearch = s:new(a:0 ? a:1 : {})

  " TODO testing of reloading

  let g:esearch.last_id += 1
  let esearch.id = g:esearch.last_id
  let g:esearch._last_search = esearch#source#pick_exp(esearch.use, esearch)
  """""""""""""""

  if !has_key(esearch, 'exp')
    let adapter_opts = esearch#adapter#{esearch.adapter}#_options()
    let esearch.exp = g:esearch._last_search
    let esearch.exp = esearch#cmdline#read(esearch, adapter_opts)

    let esearch.exp = esearch#regex#finalize(esearch.exp, esearch)
  endif

  let g:esearch.case     = esearch.case
  let g:esearch.word     = esearch.word
  let g:esearch.regex    = esearch.regex
  let g:esearch.paths    = esearch.paths
  let g:esearch.metadata = esearch.metadata

  if empty(esearch.exp)
    return 1
  endif


  " Prepare backend (nvim, vimproc, ...) request object
  """""""""""""""
  let EscapeFunc = function('esearch#backend#'.esearch.backend.'#escape_cmd')
  let pattern = esearch.regex ? esearch.exp.pcre : esearch.exp.literal
  let shell_cmd = esearch#adapter#{esearch.adapter}#cmd(esearch, pattern, EscapeFunc)
  let requires_pty = esearch#adapter#{esearch.adapter}#requires_pty()
  let esearch = extend(esearch, {
        \ 'title': s:title(esearch, pattern),
        \ 'request': esearch#backend#{esearch.backend}#init(shell_cmd, requires_pty),
        \}, 'force')

  call esearch#adapter#{esearch.adapter}#set_results_parser(esearch)

  call esearch#out#{esearch.out}#init(esearch)
endfu

fu! s:new(configuration) abort
  let configuration = extend(deepcopy(a:configuration),
        \ deepcopy(g:esearch), 'keep')
  let configuration = extend(configuration, {
        \ 'cwd': getcwd(),
        \ 'paths': [],
        \ 'metadata': [],
        \ 'glob': 0,
        \ 'visualmode': 0,
        \ 'is_single_file': function('<SID>is_single_file'),
        \ 'set_default': function('esearch#util#set_default'),
        \ 'slice': function('esearch#util#slice')
        \}, 'keep')
  return configuration
endfu

fu! s:is_single_file() abort dict
  " Some adapters don't list filenames when a single file is specified for
  " search, so this function will be used to match results using different
  " format patterns
  return len(self.paths) == 1 &&
        \ (len(self.metadata) != 1 || empty(self.metadata[0].wildcards)) &&
        \ !isdirectory(self.paths[0])
endfu

fu! s:title(esearch, pattern) abort
  let format = s:title_format(a:esearch)
  let modifiers = ''
  let modifiers .= a:esearch.case ? 'c' : ''
  let modifiers .= a:esearch.word ? 'w' : ''
  return printf(format, a:pattern, modifiers)
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
    if esearch#util#has_unicode()
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

  return 0
endfu
