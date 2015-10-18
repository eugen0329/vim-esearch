let s:opts_map = {
      \'regex':   { 'p': ['-Q', ''], 's': ['>', 'r'] },
      \'case':    { 'p': ['', '-s'], 's': ['>', 'c'] },
      \'word':    { 'p': ['', '-w'], 's': ['>', 'w'] },
      \}

fu! esearch#opts#new(opts)
  return extend(a:opts, {
        \ 'regex':           0,
        \ 'case':            0,
        \ 'word':            0,
        \ 'updatetime':      300.0,
        \ 'batch_size':      2000,
        \ 'context_width':   120,
        \ 'recover_regex':   1,
        \ 'highlight_match': 1,
        \ 'use': { 'visual': 1, 'hlsearch': 1 },
        \ 'update_statusline_cmd': s:update_statusline_cmd(),
        \ 'invert':      function('<SID>invert'),
        \ 'stringify':   function('<SID>stringify'),
        \ 'parametrize': function('<SID>parametrize'),
        \}, 'keep')
endfu

fu! s:invert(key) dict
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu

fu! s:stringify(key) dict
  return s:transformed(self, a:key, 's')
endfu

fu! s:parametrize(key) dict
  return s:transformed(self, a:key, 'p')
endfu

fu s:transformed(dict, key, kind)
  return s:opts_map[a:key][a:kind][a:dict[a:key]]
endfu

fu! s:update_statusline_cmd()
  if exists('*lightline#update_once')
    return 'call lightline#update_once()'
  elseif exists('AirlineRefresh')
    return 'AirlineRefresh'
  else
    return ''
  endif
endfu
