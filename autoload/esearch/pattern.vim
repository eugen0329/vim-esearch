let g:esearch#pattern#even_count_of_escapes =  '\%(\\\)\@<!\%(\\\\\)*'

fu! esearch#pattern#new(string, is_regex, case, textobj) abort
  let pattern = {
        \ 'is_regex': a:is_regex,
        \ 'str':      function('<SID>str'),
        \ 'literal':  a:string,
        \ 'pcre':     a:string,
        \ }

  if pattern.is_regex
    let pattern.vim = esearch#pattern#pcre2vim#convert(a:string)
  else
    let pattern.vim = esearch#pattern#literal2vim#convert(a:string)
  endif

  if a:case ==# 'ignore'
    let pattern.vim = pattern.vim.'\c'
  elseif a:case ==# 'sensitive'
    let pattern.vim = pattern.vim.'\C'
  elseif a:case ==# 'smart'
    let pattern.vim = pattern.vim . (pattern.vim =~# '\u' ? '\C' : '\c')
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

fu! s:str() abort dict
  return self.is_regex ? self.pcre : self.literal
endfu
