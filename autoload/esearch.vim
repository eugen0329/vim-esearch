fu! esearch#init(...) abort
  " if g:esearch#env is# 'dev'
  "   for path in split(glob(s:autoload . '/esearch/**/*.vim'), '\n')
  "     exe 'source' . path
  "   endfor
  " endif

  if s:init_lazy_global_config() != 0
    return 1
  endif

  let esearch = s:new(a:0 ? a:1 : {})
  let g:esearch.last_id += 1
  let esearch.id = g:esearch.last_id

  call esearch#ftdetect#async_prewarm_cache()

  if has_key(esearch, 'exp')
    let esearch.exp = esearch#regex#new(esearch.exp)
  else
    let esearch.exp  = esearch#source#pick_exp(esearch.use, esearch)
    let adapter_opts = esearch#adapter#{esearch.adapter}#_options()
    let esearch.exp  = esearch#cmdline#read(esearch, adapter_opts)
    let esearch.exp  = esearch#regex#finalize(esearch.exp, esearch)
  endif

  let g:esearch.last_search = esearch.exp
  let g:esearch.case        = esearch.case
  let g:esearch.word        = esearch.word
  let g:esearch.regex       = esearch.regex
  let g:esearch.paths       = esearch.paths
  let g:esearch.metadata    = esearch.metadata

  if empty(esearch.exp)
    return 1
  endif

  let EscapeFunc = function('esearch#backend#'.esearch.backend.'#escape_cmd')
  let pattern = esearch.regex ? esearch.exp.pcre : esearch.exp.literal
  let shell_cmd = esearch#adapter#{esearch.adapter}#cmd(esearch, pattern, EscapeFunc)
  let requires_pty = esearch#adapter#{esearch.adapter}#requires_pty()
  let esearch = extend(esearch, {
        \ 'title': s:title(esearch, pattern),
        \ 'request': esearch#backend#{esearch.backend}#init(shell_cmd, requires_pty),
        \}, 'force')

  let esearch.parse = esearch#adapter#parse#funcref()

  call esearch#out#{esearch.out}#init(esearch)
endfu

fu! s:new(configuration) abort
  let configuration = extend(deepcopy(a:configuration),
        \ deepcopy(g:esearch), 'keep')
  let configuration = extend(configuration, {
        \ 'cwd': getcwd(),
        \ 'escaped_cwd': fnameescape(getcwd()),
        \ 'paths': [],
        \ 'metadata': [],
        \ 'glob': 0,
        \ 'visualmode': 0,
        \ 'set_default': function('esearch#util#set_default'),
        \ 'slice': function('esearch#util#slice')
        \}, 'keep')

  if g:esearch#has#lua
    let configuration.lua_cwd_prefix =
          \ luaeval("'^' .. _A:gsub('([^%w])', '%%%1') .. '%/'",
          \ configuration.cwd)
  endif
  if g:esearch#has#windows
    let configuration.cwd_prefix = substitute(configuration.cwd, '\\', '\\\\', 'g').'\\'
  else
    let configuration.cwd_prefix = configuration.cwd . '/'
  endif

  return configuration
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

if !exists('g:esearch#env')
  let g:esearch#env = 0 " prod
endif
let s:autoload = vital#esearch#new().import('System.Filepath').dirname(expand('<sfile>'))
