fu! esearch#init(...) abort
  if s:init_lazy_global_config() != 0
    return 1
  endif

  " Prepare argv
  """""""""""""""
  let opts = a:0 ? a:1 : {}
  let source_params = {
        \ 'visualmode': get(opts, 'visualmode', 0),
        \}
  let initial = get(opts, 'use', g:esearch.use)
  let g:esearch._last_search = esearch#source#pick_exp(initial, source_params)
  call extend(opts, {
        \ 'set_default': function('esearch#util#set_default'),
        \ 'slice': function('esearch#util#slice')
        \})
  """""""""""""""

  " Read search string
  """""""""""""""
  call opts.set_default('cwd', getcwd())
  call opts.set_default('adapter', g:esearch.adapter)

  if !has_key(opts, 'exp')
    let adapter_opts = esearch#adapter#{opts.adapter}#_options()
    let cmdline_opts = {
          \ 'cwd': opts.cwd,
          \ 'exp': g:esearch._last_search,
          \ 'empty_cmdline': get(opts, 'empty_cmdline', 0),
          \}
    let opts.exp = esearch#cmdline#read(cmdline_opts, adapter_opts)
    if empty(opts.exp)
      return 1
    endif
    let opts.exp = esearch#regex#finalize(opts.exp, g:esearch)
  endif
  """""""""""""""


  " Prepare backend (nvim, vimproc, ...) request object
  """""""""""""""
  call opts.set_default('backend', g:esearch.backend)
  let EscapeFunc = function('esearch#backend#'.opts.backend.'#escape_cmd')
  let pattern = g:esearch.regex ? opts.exp.pcre : opts.exp.literal
  let shell_cmd = esearch#adapter#{opts.adapter}#cmd(pattern, opts.cwd, EscapeFunc)
  let requires_pty = esearch#adapter#{opts.adapter}#requires_pty()

  let request = esearch#backend#{opts.backend}#init(shell_cmd, requires_pty)
  """""""""""""""

  " Build output (window, qflist, ...) params object
  """""""""""""""
  call opts.set_default('batch_size', g:esearch.batch_size)
  call opts.set_default('out', g:esearch.out)
  call opts.set_default('context_width', g:esearch.context_width)
  let out_params = extend(opts.slice('backend', 'adapter', 'cwd', 'exp', 'out', 'batch_size', 'context_width'), {
        \ 'title': s:title(pattern),
        \ 'request': request,
        \})
  """""""""""""""

  call esearch#out#{opts.out}#init(out_params)
endfu

fu! s:title(pattern) abort
  let format = s:title_format()
  let modifiers = ''
  let modifiers .= g:esearch.case ? 'c' : ''
  let modifiers .= g:esearch.word ? 'w' : ''
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
fu! s:title_format() abort
  if g:esearch.regex
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

  if !has_key(global_esearch, '__lazy_loaded')
    let g:esearch = esearch#opts#new(global_esearch)
    if empty(g:esearch) | return 1 | endif
    let g:esearch.__lazy_loaded = 1
  endif

  return 0
endfu

function! esearch#sid() abort
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>
