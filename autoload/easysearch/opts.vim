let s:opts_map = {
      \'regex':   { 'p': '-Q', 's': 'r' },
      \'case':    { 'p': '-s', 's': 'c' },
      \'word':    { 'p': '-w', 's': 'w' },
      \'default': { 'p': '',   's': '>' },
      \}

fu! easysearch#opts#new(opts)
  return extend(a:opts, {
        \'regex':       0,
        \'case':        0,
        \'word':        0,
        \'invert':      function('<SID>invert'),
        \'stringify':   function('<SID>stringify'),
        \'parametrize': function('<SID>parametrize'),
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

fu s:transformed(self, key, kind)
  if a:self[a:key]
    return s:opts_map[a:key][a:kind]
  endif
  return s:opts_map.default[a:kind]
endfu
