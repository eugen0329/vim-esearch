fu! esearch#opts#new(opts) abort
  let opts = extend(a:opts, {
        \ 'out':             'win',
        \ 'backend':         has('nvim') ? 'nvim' : 'dispatch',
        \ 'regex':           0,
        \ 'case':            0,
        \ 'word':            0,
        \ 'updatetime':      300.0,
        \ 'batch_size':      1000,
        \ 'ticks':           3,
        \ 'context_width':   { 'l': 60, 'r': 60 },
        \ 'recover_regex':   1,
        \ 'highlight_match': 1,
        \ 'escape_special':  1,
        \ 'wordchars':      'a-z,A-Z,_',
        \ 'use': ['visual', 'hlsearch', 'last'],
        \ 'nerdtree_plugin': 1,
        \ 'invert':           function('<SID>invert'),
        \ 'require':          function('esearch#util#require'),
        \}, 'keep')
  if !has_key(opts, 'adapter')
    if executable('ag')
      let opts.adapter = 'ag'
    elseif executable('ack')
      let opts.adapter = 'ack'
    elseif executable('grep')
      " TODO
    endif
  endif
  return opts
endfu

fu! s:invert(key) dict abort
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu
