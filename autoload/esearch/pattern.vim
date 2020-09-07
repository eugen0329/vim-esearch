" Returns |Dict| that holds different views of the same pattern:
" .arg     - in a syntax to pass as a search util argument
" .vim     - in vim 'nomagic' syntax to hl or interact with matches within vim
" .literal - in --fixed-strings sytax for prefilling the cmdline
" .pcre    - in perl compatible syntax for prefilling the cmdline
fu! esearch#pattern#new(str, regex, case, textobj) abort
  " Conversions literal2pcre(str) or pcre2literal(str) don't happen, as these
  " attrs are only used to prefill the cmdline in further searches, so no strong
  " need to implement extra converters
  return s:Regex.new(a:str).convert(a:regex, a:case, a:textobj)
endfu

let s:Regex = {}

fu! s:Regex.new(str, ...) abort dict
  return extend(copy(self), {'str': a:str, 'opt': get(a:, 1, '')})
endfu

fu! s:Regex.convert(esearch) abort dict
  let new = {'arg': self.str, 'literal': self.str, 'pcre': self.str}

  if a:esearch.regex ==# 'literal'
    let new.vim = esearch#pattern#literal2vim#convert(self.str)
  else
    let new.vim = esearch#pattern#pcre2vim#convert(self.str)
  endif

  if a:esearch.case ==# 'ignore'
    let new.vim = new.vim.'\c'
  elseif a:esearch.case ==# 'sensitive'
    let new.vim = new.vim.'\C'
  elseif a:esearch.case ==# 'smart'
    let new.vim = new.vim . (esearch#util#has_upper(self.str) ? '\C' : '\c')
  elseif g:esearch#env isnot# 0
    echoerr 'Unknown case option ' . a:esearch.case
  endif

  if a:esearch.textobj ==# 'word'
    let new.vim = '\%(\<\|\>\)'.new.vim.'\%(\<\|\>\)'
  elseif a:esearch.textobj ==# 'line'
    let new.vim = '^'.new.vim.'$'
  endif

  return new
endfu

fu! esearch#pattern#set(spec, ...) abort
  return s:PatternSet.new(a:spec, get(a:, 1, ''))
endfu

let s:Literal = {}

fu! s:Literal.new(str, ...) abort dict
  return extend(copy(self), {'str': a:str, 'opt': get(a:, 1, '')})
endfu

fu! s:Literal.convert(esearch) abort dict
  return {'arg': self.str, 'literal': self.str, 'pcre': self.str}
endfu

let s:PatternSet = {}

fu! s:PatternSet.new(spec, str) abort dict
  let new = copy(self)
  let new.spec = esearch#util#cycle(a:spec)
  let kind = a:spec[0]
  let new.patterns = esearch#util#cycle([kind.regex ? s:Regex.new(a:str, kind.opt) : s:Literal.new(a:str, kind.opt)])
  return new
endfu

fu! s:PatternSet.replace(str) abort dict
  let curr = self.patterns.curr()
  return extend(curr, {'str': a:str})
endfu

fu! s:PatternSet.next() abort dict
  let curr = self.patterns.curr()
  if !empty(curr.str) | return self.patterns.next() | endif

  let kind = self.spec.next()
  let blank_pattern = kind.regex ? s:Regex.new('', kind.opt) : s:Literal.new('', kind.opt)
  return self.patterns.replace(blank_pattern)
endfu

fu! s:PatternSet.curr() abort dict
  return self.patterns.curr()
endfu

fu! s:PatternSet.convert(esearch) abort dict
  let self.converted = map(copy(self.patterns.list), 'v:val.convert(a:esearch)')
  let self.arg = join(map(copy(self.converted), 'shellescape(v:val.arg)'), ' ')

  let first = self.converted[0]
  if has_key(first, 'literal') | let self.literal = first.literal | endif
  if has_key(first, 'pcre')    | let self.pcre = first.pcre       | endif
  if len(self.converted) > 1 | return | endif
  if has_key(first, 'vim')     | let self.vim = first.vim         | endif
endfu
