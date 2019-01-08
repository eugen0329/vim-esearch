fu! esearch#opts#new(opts) abort
  let opts = copy(a:opts)

  if !has_key(opts, 'backend')
    if has('nvim') && exists('*jobstart')
      let opts.backend = 'nvim'
    elseif s:vim8_is_supported()
      let opts.backend = 'vim8'
    elseif esearch#util#has_vimproc()
      let opts.backend = 'vimproc'
    else
      " call esearch#help#backend_dependencies()
      let opts.backend = 'system'
    endif
  endif

  if !has_key(opts, 'adapter')
    if executable('rg')
      let opts.adapter = 'rg'
    elseif executable('ag')
      let opts.adapter = 'ag'
    elseif executable('pt')
      let opts.adapter = 'pt'
    elseif executable('rg')
      let opts.adapter = 'rg'
    elseif executable('ack')
      let opts.adapter = 'ack'
    elseif !system('git rev-parse --is-inside-work-tree >/dev/null 2>&1') && !v:shell_error
      let opts.adapter = 'git'
    elseif executable('grep')
      let opts.adapter = 'grep'
    endif
  endif

  let opts = extend(opts, {
        \ 'out':              'win',
        \ 'regex':            0,
        \ 'case':             0,
        \ 'word':             0,
        \ 'batch_size':       1000,
        \ 'context_width':    { 'l': 60, 'r': 60 },
        \ 'recover_regex':    1,
        \ 'highlight_match':  1,
        \ 'escape_special':   1,
        \ 'default_mappings': g:esearch#defaults#default_mappings,
        \ 'nerdtree_plugin':  1,
        \ 'invert':           function('<SID>invert'),
        \ 'slice':            function('esearch#util#slice'),
        \ 'errors':           [],
        \ 'use': ['visual', 'hlsearch', 'current', 'last'],
        \}, 'keep')

  return opts
endfu

fu! s:invert(key) dict abort
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu

fu! s:vim8_is_supported() abort
  return has('job') &&
        \ esearch#util#vim8_job_start_close_cb_implemented() &&
        \ (esearch#util#vim8_calls_close_cb_last() || exists('*timer_start'))
endfu
