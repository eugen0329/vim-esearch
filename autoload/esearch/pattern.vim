let g:esearch#pattern#even_count_of_escapes =  '\%(\\\)\@<!\%(\\\\\)*'

fu! esearch#pattern#new(str, regex, case, textobj) abort
  let pattern = {'str': a:str}

  if a:regex ==# 'literal'
    let pattern.vim = esearch#pattern#literal2vim#convert(a:str)
  else
    let pattern.vim = esearch#pattern#pcre2vim#convert(a:str)
  endif

  " Modifiers are set to the back to:
  " - not overrule the modifiers specified inside
  " - be able to overwrite ^ in the beginning using the first char
  "   replacement. See #win#appearance#matches for details.
  if a:case ==# 'ignore'
    let pattern.vim = pattern.vim.'\c'
  elseif a:case ==# 'sensitive'
    let pattern.vim = pattern.vim.'\C'
  elseif a:case ==# 'smart'
    " NOTE that \u <=> [A-Z], so if the output contains ASCII only, this will
    " work as usual 'smartcase', but if there's a unicode char, then false
    " positive matches are possible
    let pattern.vim = pattern.vim . (a:str =~# '\u' ? '\C' : '\c')
  elseif g:esearch#env isnot# 0
    echoerr 'Unknown case option ' . a:case
  endif

  if a:textobj ==# 'word'
    let pattern.vim = '\%(\<\|\>\)'.pattern.vim.'\%(\<\|\>\)'
  elseif a:textobj ==# 'line'
    let pattern.vim = '^'.pattern.vim.'$'
  endif

  return pattern
endfu
