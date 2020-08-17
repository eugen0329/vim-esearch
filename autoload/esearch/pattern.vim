" Returns |Dict| that holds different views of the same pattern:
" .arg     - in a syntax to pass as a search util argument
" .vim     - in vim 'nomagic' syntax to hl or interact with matches within vim
" .literal - in --fixed-strings sytax for prefilling the cmdline
" .pcre    - in perl compatible syntax for prefilling the cmdline
fu! esearch#pattern#new(str, regex, case, textobj) abort
  " Conversions literal2pcre(str) or pcre2literal(str) don't happen, as these
  " attrs are only used to prefill the cmdline in further searches, so no strong
  " need to implement extra converters
  let pattern = {'arg': a:str, 'literal': a:str, 'pcre': a:str}

  if a:regex ==# 'literal'
    let pattern.vim = esearch#pattern#literal2vim#convert(a:str)
  else
    let pattern.vim = esearch#pattern#pcre2vim#convert(a:str)
  endif

  if a:case ==# 'ignore'
    let pattern.vim = pattern.vim.'\c'
  elseif a:case ==# 'sensitive'
    let pattern.vim = pattern.vim.'\C'
  elseif a:case ==# 'smart'
    let pattern.vim = pattern.vim . (esearch#util#has_upper(a:str) ? '\C' : '\c')
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
