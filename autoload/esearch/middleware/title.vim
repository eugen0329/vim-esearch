" 1 day age is required for UX to not break the ids sequence within a day.
" Size limitation is required to prevent bloats
let s:pattern2id = esearch#cache#expiring#new({'max_age': 60 * 60 * 24, 'size': 1024})
" Vim supports ~ 240 bytes in buffer names, but to prevent tab/statuslines from
" being completely occupied by a title this number should be much smaller.
let s:max_len = 120

fu! esearch#middleware#title#apply(esearch) abort
  let a:esearch.title = s:title(a:esearch, a:esearch.pattern.str)
  return a:esearch
endfu

fu! s:title(esearch, pattern) abort
  let format = s:format(a:esearch)
  let [id, pattern] = s:informative_parts(a:esearch, a:pattern)
  let pattern = substitute(pattern, '%', '%%', 'g') " escape for using in the statusline
  let modifiers = s:modifiers(a:esearch)

  return printf(format, id, pattern, modifiers)
endfu

fu! s:format(esearch) abort
  if a:esearch.regex ==# 'literal'
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

" For short patterns will be:
"   Search <pattern>modifiers
" For long patterns:
"   Search #id <ellipsized_pattern>modifiers
fu! s:informative_parts(esearch, pattern) abort
  let max_len = min([s:max_len, &columns / 2])

  if strlen(a:pattern) < max_len
    return ['', a:pattern]
  endif

  if s:pattern2id.has(a:pattern)
    let id = s:pattern2id.get(a:pattern)
  else
    let id = a:esearch.id
    call s:pattern2id.set(a:pattern, id)
  endif

  return ['#'.id.' ', esearch#util#ellipsize_end(a:pattern, max_len, '..')]
endfu

fu! s:modifiers(esearch) abort
  let modifiers  = get(a:esearch.current_adapter.case,  a:esearch.case,  {'icon': ''}).icon
  let regex_icon = get(a:esearch.current_adapter.regex, a:esearch.regex, {'icon': ''}).icon
  if regex_icon !=# 'r' " as default regexps are hinted using /%s/ in the format
    let modifiers .= regex_icon
  endif
  let modifiers .= get(a:esearch.current_adapter.textobj, a:esearch.textobj, {'icon': ''}).icon

  return modifiers
endfu
