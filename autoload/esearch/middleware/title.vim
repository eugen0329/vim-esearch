fu! esearch#middleware#title#apply(esearch) abort
  let a:esearch.title = s:title(a:esearch, a:esearch.pattern.str())

  return a:esearch
endfu

fu! s:title(esearch, pattern) abort
  let format = s:title_format(a:esearch)
  let modifiers  = get(a:esearch.current_adapter.spec.case, a:esearch.case, {'icon': ''}).icon
  let regex_icon = get(a:esearch.current_adapter.spec.regex, a:esearch.regex, {'icon': ''}).icon
  if regex_icon !=# 'r'
    let modifiers .= regex_icon
  endif
  let modifiers .= get(a:esearch.current_adapter.spec.textobj, a:esearch.textobj, {'icon': ''}).icon
  return printf(format, substitute(a:pattern, '%', '%%', 'g'), modifiers)
endfu

fu! s:title_format(esearch) abort
  if a:esearch.is_regex()
    if g:esearch#has#unicode
      return printf('Search %s%%s%s%%s', g:esearch#unicode#slash, g:esearch#unicode#slash)
    else
      return "Search r'%s'%s"
    endif
  else
    if g:esearch#has#unicode
      return printf('Search %s%%s%s%%s', g:esearch#unicode#quote_left, g:esearch#unicode#quote_right)
    else
      return 'Search <%s>%s'
    endif
  endif
endfu
