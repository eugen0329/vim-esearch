let s:pattern2id = esearch#cache#expiring#new({'max_age': 60 * 60 * 24, 'size': 1024})
" Vim supports ~ 240 bytes in buffer names, but to prevent tab/statuslines from being
" completely occupied by a single buffer title this number should be much smaller.
let s:max_len = 120

if g:esearch#has#unicode
  let s:regex_fmt =  'Search %s'.g:esearch#unicode#slash.'%s'.g:esearch#unicode#slash.'%s'
  let s:literal_fmt = 'Search %s'.g:esearch#unicode#quote_left.'%s'.g:esearch#unicode#quote_right.'%s'
else
  let s:literal_fmt = 'Search %s<%s>%s'
  let s:regex_fmt "Search %sr'%s'%s"
endif

fu! esearch#middleware#name#apply(esearch) abort
  if has_key(a:esearch, 'name') | return a:esearch | endif
  let a:esearch.name = s:name(a:esearch, a:esearch.pattern.str)
  return a:esearch
endfu

fu! s:name(esearch, pattern) abort
  let fmt = index([0, 'literal'], a:esearch.regex) >= 0 ? s:literal_fmt : s:regex_fmt
  let [id, pattern] = s:informative_parts(a:esearch, a:pattern)
  let pattern = esearch#util#escape_for_statusline(pattern)
  let modifiers = s:modifiers(a:esearch)

  return printf(fmt, id, pattern, modifiers)
endfu

fu! s:informative_parts(esearch, pattern) abort
  let max_len = min([s:max_len, &columns / 2])
  if strlen(a:pattern) < max_len
        \ && empty(a:esearch.paths)
        \ && empty(a:esearch.globs.list)
        \ && empty(a:esearch.filetypes)
    return ['', a:pattern]
  endif

  let key = a:pattern
        \ . string(a:esearch.paths)
        \ . string(a:esearch.globs.list)
        \ . string(a:esearch.filetypes)
  if s:pattern2id.has(key)
    let id = s:pattern2id.get(key)
  else
    let id = a:esearch.id
    call s:pattern2id.set(key, id)
  endif

  return ['#'.id.' ', esearch#util#ellipsize_end(a:pattern, max_len, '..')]
endfu

fu! s:modifiers(esearch) abort
  let regex_icon = get(a:esearch._adapter.regex, a:esearch.regex, {'icon': ''}).icon
  return (regex_icon ==# 'r' ? '' : regex_icon) " don't show default regex icon
        \ . get(a:esearch._adapter.case,  a:esearch.case,  {'icon': ''}).icon
        \ . get(a:esearch._adapter.textobj, a:esearch.textobj, {'icon': ''}).icon
endfu
