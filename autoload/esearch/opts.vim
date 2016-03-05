let s:opts_map = {
      \'regex':   { 'p': ['-Q', ''],   's': ['>', 'r'] },
      \'case':    { 'p': ['-i', '-s'], 's': ['>', 'c'] },
      \'word':    { 'p': ['',   '-w'], 's': ['>', 'w'] },
      \}

fu! esearch#opts#new(opts) abort
  return extend(a:opts, {
        \ 'regex':           0,
        \ 'case':            0,
        \ 'word':            0,
        \ 'updatetime':      300.0,
        \ 'batch_size':      2000,
        \ 'context_width':   { 'l': 60, 'r': 60 },
        \ 'recover_regex':   1,
        \ 'highlight_match': 1,
        \ 'escape_special':  1,
        \ 'wordchars':      'a-z,A-Z,_',
        \ 'use': ['visual', 'hlsearch', 'last'],
        \ 'nerdtree_plugin': 1,
        \ 'update_statusline_cmd': s:update_statusline_cmd(),
        \ 'invert':      function('<SID>invert'),
        \ 'stringify':   function('<SID>stringify'),
        \ 'parametrize': function('<SID>parametrize'),
        \}, 'keep')
endfu

fu! s:invert(key) dict abort
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu

fu! s:stringify(key) dict abort
  return s:transformed(self, a:key, 's')
endfu

fu! s:parametrize(key) dict abort
  return s:transformed(self, a:key, 'p')
endfu

fu s:transformed(dict, key, kind) abort
  return s:opts_map[a:key][a:kind][a:dict[a:key]]
endfu

fu! s:update_statusline_cmd() abort
  if exists('*lightline#update_once')
    return 'call lightline#update_once()'
  elseif exists('AirlineRefresh')
    return 'AirlineRefresh'
  else
    return ''
  endif
endfu
