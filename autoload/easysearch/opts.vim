fu! easysearch#opts#new(opts)
  return extend(a:opts, {
        \'regex': 0,
        \'invert': function('<SID>invert'),
        \}, 'keep')
endfu

fu! s:invert(key) dict
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu

