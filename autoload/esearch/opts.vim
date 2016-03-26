fu! esearch#opts#new(opts) abort
  let opts = copy(a:opts)

  if !has_key(opts, 'backend')
    if has('nvim') && exists('*jobstart')
      let opts.backend = 'nvim'
    elseif esearch#util#has_vimproc()
      let opts.backend = 'vimproc'
    else
      call esearch#util#highlight('Error', 'ESearch plugin requires NeoVim job control or Vimproc plugin installed', 0)
      echo "See:\n\thttps://neovim.io/doc/user/job_control.html\n\thttps://github.com/Shougo/vimproc.vim"
      return 0
    endif
  endif

  if !has_key(opts, 'adapter')
    if executable('ag')
      let opts.adapter = 'ag'
    elseif executable('pt')
      let opts.adapter = 'pt'
    elseif executable('ack')
      let opts.adapter = 'ack'
    elseif executable('grep')
      let opts.adapter = 'grep'
    endif
  endif

  let opts = extend(opts, {
        \ 'out':             'win',
        \ 'regex':           0,
        \ 'case':            0,
        \ 'word':            0,
        \ 'batch_size':      1000,
        \ 'context_width':   { 'l': 60, 'r': 60 },
        \ 'recover_regex':   1,
        \ 'highlight_match': 1,
        \ 'escape_special':  1,
        \ 'wordchars':      'a-z,A-Z,_',
        \ 'use': ['visual', 'hlsearch', 'last'],
        \ 'nerdtree_plugin': 1,
        \ 'invert':           function('<SID>invert'),
        \ 'require':          function('esearch#util#require'),
        \ 'errors':          [],
        \}, 'keep')

  return opts
endfu

fu! s:invert(key) dict abort
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu
