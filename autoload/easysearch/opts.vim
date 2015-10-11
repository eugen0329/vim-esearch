fu! easysearch#opts#new(opts)
  return extend(a:opts, {
        \'regex':     0,
        \'invert':    function('<SID>invert'),
        \'stringify': function('<SID>stringify'),
        \}, 'keep')
endfu

fu! s:invert(key) dict
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu

fu! s:stringify(key) dict
  if self[a:key]
    return a:key[0]
  endif
  return '>'
endfu
