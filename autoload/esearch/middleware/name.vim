let s:pattern2id = esearch#cache#expiring#new({'max_age': 60 * 60 * 24, 'size': 1024})
" Vim supports ~ 240 bytes in buffer names, but to prevent tab/statuslines from being
" completely occupied by a single buffer title this number should be much smaller.
let s:max_len = 120

fu! esearch#middleware#name#apply(esearch) abort
  if has_key(a:esearch, 'name') | return a:esearch | endif
  let a:esearch.name = s:name(a:esearch, a:esearch.pattern.str)
  return a:esearch
endfu

" For short patterns and if no paths provided titles are:
"   Search <pattern>modifiers
" else:
"   Search #id <ellipsized_pattern>modifiers
fu! s:name(esearch, pattern) abort
  let format = s:format(a:esearch)
  let [id, pattern] = s:informative_parts(a:esearch, a:pattern)
  let pattern = esearch#util#escape_for_statusline(pattern)
  let modifiers = s:modifiers(a:esearch)

  return printf(format, id, pattern, modifiers)
endfu

fu! s:format(esearch) abort
  if index([0, 'literal'], a:esearch.regex) >= 0
    if g:esearch#has#unicode
      return 'Search %s'.g:esearch#unicode#quote_left.'%s'.g:esearch#unicode#quote_right.'%s'
    else
      return 'Search %s<%s>%s'
    endif
  endif

  if g:esearch#has#unicode
    return 'Search %s'.g:esearch#unicode#slash.'%s'.g:esearch#unicode#slash.'%s'
  else
    return "Search %sr'%s'%s"
  endif
endfu

" Returns [search_id, ellipsized_pattern]
" search_id is blank if pattern is short enough and if no paths are given.
fu! s:informative_parts(esearch, pattern) abort
  let max_len = min([s:max_len, &columns / 2])

  if strlen(a:pattern) < max_len && empty(a:esearch.paths)
    return ['', a:pattern]
  endif

  let key = a:pattern . string(a:esearch.paths)
  if s:pattern2id.has(key)
    let id = s:pattern2id.get(key)
  else
    let id = a:esearch.id
    call s:pattern2id.set(key, id)
  endif

  return ['#'.id.' ', esearch#util#ellipsize_end(a:pattern, max_len, '..')]
endfu

fu! s:modifiers(esearch) abort
  let modifiers  = get(a:esearch._adapter.case,  a:esearch.case,  {'icon': ''}).icon
  let regex_icon = get(a:esearch._adapter.regex, a:esearch.regex, {'icon': ''}).icon
 " don't show default regexp modifiers, hint with wrapping backslashes instead
  if regex_icon !=# 'r'
    let modifiers .= regex_icon
  endif
  let modifiers .= get(a:esearch._adapter.textobj, a:esearch.textobj, {'icon': ''}).icon

  return modifiers
endfu
