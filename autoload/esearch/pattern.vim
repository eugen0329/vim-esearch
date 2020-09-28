fu! esearch#pattern#new(adapter, str) abort
  return s:PatternSet.new(a:adapter.pattern_kinds, a:str)
endfu

let s:PatternSet = {}

" Produce |Dict| that holds different views of the same pattern:
" .arg     - in a syntax to pass as a search util argument
" .vim     - in vim 'nomagic' syntax to hl or interact with matches within vim
" .literal - in --fixed-strings sytax for prefilling the cmdline
" .pcre    - in perl compatible syntax for prefilling the cmdline
" .str     - in string representatino of a pattern for buffer names

fu! s:PatternSet.splice(esearch) abort dict
  let self.arg = join(map(copy(self.patterns.list), 'v:val.opt . v:val.convert(a:esearch).arg'))

  if self.patterns.len() > 1
    let self.str = self.arg
    return
  endif

  let top = self.patterns.top()
  let self.str = top.str
  if has_key(top, 'literal') | let self.literal = top.literal | endif
  if has_key(top, 'pcre')    | let self.pcre = top.pcre       | endif
  if has_key(top, 'vim')     | let self.vim = top.vim         | endif
endfu

fu! s:PatternSet.new(kinds, str) abort dict
  let new = copy(self)
  let new.kinds = esearch#util#cycle(a:kinds)
  let new.patterns = esearch#util#stack([s:Pattern.from_kind(new.kinds.next(), a:str)])
  return new
endfu

fu! s:PatternSet.adapt(adapter) abort dict
  let kinds = a:adapter.pattern_kinds
  if kinds ==# self.kinds.list | return | endif

  let self.kinds = esearch#util#cycle(kinds)
  let self.patterns = esearch#util#stack([s:Pattern.from_kind(self.kinds.next(), self.patterns.top().str)])
endfu

fu! s:PatternSet.replace(str) abort dict
  return self.patterns.replace(extend(copy(self.patterns.top()), {'str': a:str}))
endfu

fu! s:PatternSet.push() abort dict
  return self.patterns.push(s:Pattern.from_kind(self.kinds.next(), ''))
endfu

fu! s:PatternSet.pop() abort dict
  if self.patterns.len() < 2 | return | endif
  return self.patterns.pop()
endfu

fu! s:PatternSet.next() abort dict
  return self.patterns.replace(s:Pattern.from_kind(self.kinds.next(), self.peek().str))
endfu

fu! s:PatternSet.peek() abort dict
  return self.patterns.top()
endfu

let s:Pattern = {}

fu! s:Pattern.new(opt, str) abort dict
  return extend(copy(self), {'opt': a:opt, 'str': a:str})
endfu

fu! s:Pattern.from_kind(kind, str) abort
  let klass = a:kind.regex ? s:Regex : s:Plaintext
  return klass.new(a:kind.opt, a:str)
endfu

let s:Regex = copy(s:Pattern)

fu! s:Regex.convert(esearch) abort dict
  " Conversions literal2pcre(str) or pcre2literal(str) don't happen, as these
  " attrs are only used to prefill the cmdline in further searches, so no strong
  " need to implement extra converters
  let self.arg = shellescape(self.str)
  let self.literal = self.str
  let self.pcre = self.str

  if a:esearch.regex is# 'literal'
    let self.vim = esearch#pattern#literal2vim#convert(self.str)
  else
    let self.vim = esearch#pattern#pcre2vim#convert(self.str)
  endif

  if a:esearch.case ==# 'ignore'
    let self.vim = self.vim.'\c'
  elseif a:esearch.case ==# 'sensitive'
    let self.vim = self.vim.'\C'
  elseif a:esearch.case ==# 'smart'
    let self.vim = self.vim . (esearch#util#has_upper(self.str) ? '\C' : '\c')
  elseif g:esearch#env isnot# 0
    echoerr 'Unknown case option ' . a:esearch.case
  endif

  if a:esearch.textobj ==# 'word'
    let self.vim = '\%(\<\|\>\)'.self.vim.'\%(\<\|\>\)'
  elseif a:esearch.textobj ==# 'line'
    let self.vim = '^'.self.vim.'$'
  endif

  return self
endfu

let s:Plaintext = copy(s:Pattern)

fu! s:Plaintext.convert(_esearch) abort dict
  let self.arg = shellescape(self.str)
  let self.literal = self.str
  let self.pcre = self.str

  return self
endfu
