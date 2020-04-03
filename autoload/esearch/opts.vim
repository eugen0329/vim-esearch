fu! esearch#opts#new(opts) abort
  let opts = copy(a:opts)

  if !has_key(opts, 'backend')
    if g:esearch#has#nvim_jobs
      let opts.backend = 'nvim'
    elseif g:esearch#has#vim8_jobs
      let opts.backend = 'vim8'
    elseif g:esearch#has#vimproc()
      let opts.backend = 'vimproc'
    else
      let opts.backend = 'system'
    endif
  endif

  if !has_key(opts, 'adapter')
    let opts.adapter = esearch#opts#default_adapter()
  endif

  if g:esearch#has#nvim_lua
    let batch_size = 5000
    let final_batch_size = 15000
  elseif g:esearch#has#vim_lua
    let batch_size = 2500
    let final_batch_size = 5000
  else
    let batch_size = 1000
    let final_batch_size = 4000
  endif

  " pt implicitly matches using regexp when ignore-case mode is enabled. Setting
  " case mode to 'sensitive' makes pt adapter more predictable and slightly
  " more similar to the default behavior of other adapters.
  if !has_key(opts, 'case')
    if opts.adapter ==# 'pt'
      let opts.case = 'sensitive'
    else
      let opts.case = 'ignore'
    endif
  endif

  " root_markers are made to correspond g:ctrlp_root_markers default value
  let opts = extend(opts, {
        \ 'out':              g:esearch#defaults#out,
        \ 'regex':            'literal',
        \ 'full':            'none',
        \ 'adapters':         {},
        \ 'batch_size':       batch_size,
        \ 'final_batch_size': final_batch_size,
        \ 'context_width':    { 'left': 60, 'right': 60 },
        \ 'after':            0,
        \ 'before':           0,
        \ 'context':          0,
        \ 'default_mappings': g:esearch#defaults#default_mappings,
        \ 'nerdtree_plugin':  1,
        \ 'root_markers':     ['.git', '.hg', '.svn', '.bzr', '_darcs'],
        \ 'invert':           function('<SID>invert'),
        \ 'slice':            function('esearch#util#slice'),
        \ 'errors':           [],
        \ 'use':              ['visual', 'hlsearch', 'current', 'last'],
        \}, 'keep')

  return opts
endfu

fu! esearch#opts#default_adapter() abort
  if executable('rg')
    return 'rg'
  elseif executable('ag')
    return 'ag'
  elseif executable('pt')
    return 'pt'
  elseif executable('ack')
    return 'ack'
  elseif !system('git rev-parse --is-inside-work-tree >/dev/null 2>&1') && !v:shell_error
    return 'git'
  elseif executable('grep')
    return 'grep'
  else
    throw 'No executables found'
  endif
endfu

fu! s:invert(key) dict abort
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu

" TODO
fu! esearch#opts#init_lazy_global_config() abort
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

