let s:Lexer  = vital#esearch#import('Text.Lexer')
let s:Parser = vital#esearch#import('Text.Parser')

let g:esearch#pattern#pcre2vim#bound = '\%(\<\|\>\)'
let g:esearch#pattern#pcre2vim#hat = "\<plug>hat"

" NOTE: is not intended to be a general purpose converter as some of atoms are
" suppressed for using in #out#win

fu! esearch#pattern#pcre2vim#convert(string) abort
  try
    let tokens = s:PCRE2Vim.new(a:string).convert()
  catch /^PCRE2Vim:/
    call esearch#util#warn(printf("Can't convert %s to vim regex dialect for matches highlight (reason: %s)",
          \ string(a:string),
          \ substitute(v:exception, '^PCRE2Vim: ', '', ''),
          \ ))
    return ''
  endtry

  let converted = join(tokens, '')

  try
    " Simple validation to ensure that the pattern is converted correctly
    call match('', '.*' . converted)
  catch
    if g:esearch#env isnot# 0
      echomsg v:exception . ' at ' . v:throwpoint
    endif
    return ''
  endtry

  return converted
endfu

let s:PCRE2Vim = {
      \ 'case_sensitive': 1,
      \ 'token':          'NULL',
      \ 'contexts':       [],
      \ 'result':         [],
      \ 'p':              0,
      \ }

fu! s:PCRE2Vim.new(text) abort dict
  let lexer = s:Lexer.lexer(s:rules).exec(a:text)
  let instance = extend(s:Parser.parser().exec(lexer), deepcopy(self))
  let instance.text = a:text
  return instance
endfu

" https:/\p{/www.regular-expressions.info/modifiers.html
let s:modifiers_set = '[\-bcdeimnpqstwx]\+'
let s:modifiers_span_re = printf('(?%s:', s:modifiers_set)
let s:modifiers_re      = printf('(?%s)', s:modifiers_set)
unlet s:modifiers_set
let s:comment_re = '(?#\%('.g:esearch#util#even_count_of_escapes_re.'\\)\|[^)]\)*)'
let s:posix_named_set_re = printf('\[:\%%(%s\):\]', join([
      \ 'alnum', 'alpha', 'blank', 'cntrl', 'digit', 'graph', 'lower', 'print',
      \ 'punct', 'space', 'upper', 'xdigit', 'return', 'tab', 'escape',
      \ 'backspace', 'word', 'ascii'], '\|'))
let s:range_quantifier_re   = '{\%(\d\+\|\d\+,\d*\)}[+?]\='
let s:capture_range_quantifier = '{\zs\%(\d\+\|\d\+,\d*\)\ze}[+?]\='
" Very rough match
let s:bracketed_escape_re = '\%(\\[xou]{\x\+}\)'
let s:POSIX_NAMED_SET   = 1
let s:SET_START         = 2
let s:SET_END           = 3
let s:MODIFIER          = 4
let s:MODIFIER_SPAN     = 5
let s:COMMENT           = 6
let s:NAMED_GROUP_START = 7
let s:GROUP_START       = 8
let s:GROUP_END         = 9
let s:RANGE_QUANTIFER   = 10
let s:QUANTIFIER        = 11
let s:PROPERTY          = 12
let s:BRACKETED_ESCAPE  = 13
let s:ESCAPED_ANY       = 14
let s:ANY               = 15
let s:rules = [
      \ [s:POSIX_NAMED_SET,   s:posix_named_set_re                     ],
      \ [s:SET_START,         '\[\^\='                                 ],
      \ [s:SET_END,           '\]'                                     ],
      \ [s:MODIFIER,          s:modifiers_re                           ],
      \ [s:MODIFIER_SPAN,     s:modifiers_span_re                      ],
      \ [s:COMMENT,           s:comment_re                             ],
      \ [s:NAMED_GROUP_START, '(?\%(P\=<\w\+>\|''\w\+''\)'             ],
      \ [s:GROUP_START,       '(\%(?<=\|?<!\|?=\|?!\|?>\|?:\|?|\)\='   ],
      \ [s:GROUP_END,         ')'                                      ],
      \ [s:RANGE_QUANTIFER,   s:range_quantifier_re                    ],
      \ [s:QUANTIFIER,        '\%(??\|\*?\|+?\|?+\|\*+\|++\|?\|+\|\*\)'],
      \ [s:PROPERTY,          '\\[Pp]{\w\+}'                           ],
      \ [s:BRACKETED_ESCAPE,  s:bracketed_escape_re                    ],
      \ [s:ESCAPED_ANY,       '\\.'                                    ],
      \ [s:ANY,               '\%([[:alnum:][:blank:]''"/\-]\+\|.\)'   ],
      \]

let s:pcre2vim_escape = {
      \ '|': '\|',
      \ '~': '\~',
      \ '^': g:esearch#pattern#pcre2vim#hat,
      \}
let s:pcre2vim_unescape_regular = {
      \ '\&': '&',
      \ '\{': '{',
      \ '\%': '%',
      \ '\<': '<',
      \ '\>': '>',
      \ '\(': '(',
      \ '\)': ')',
      \ '\?': '?',
      \ '\+': '+',
      \ '\|': '|',
      \ '\=': '=',
      \ '\@': '@',
      \ '\_': '_',
      \}
let s:pcre2vim_expand_escaped = extend({
      \ '\A': g:esearch#pattern#pcre2vim#hat,
      \ '\z': '$',
      \ '\Z': '$',
      \ '\G': '',
      \ '\b': g:esearch#pattern#pcre2vim#bound,
      \ '\B': '\%(\w\)\@<=\%(\w\)\@=',
      \ '\K': '',
      \}, s:pcre2vim_unescape_regular)
" NOTE: possessive are converted to greedy. https:/\p{/github.com/vim/vim/issues/4638
let s:pcre2vim_quantifier = {
      \ '*':  '*',
      \ '+':  '\+',
      \ '*+': '*',
      \ '++': '\+',
      \ '?':  '\=',
      \ '?+': '\=',
      \ '*?': '\{-}',
      \ '+?': '\{-1,}',
      \ '??': '\{-,1}',
      \}
let s:pcre2vim_group_start = {
      \ '(?<=': '\%(',
      \ '(?<!': '\%(',
      \ '(?=':  '\%(',
      \ '(?!':  '\%(',
      \ '(?>':  '\%(',
      \ '(?:':  '\%(',
      \ '(?|':  '\(',
      \ '(':    '\(',
      \}
let s:pcre2vim_group_end = {
      \ '(?<=': '\)\@<=',
      \ '(?<!': '\)\@<!',
      \ '(?=':  '\)\@=',
      \ '(?!':  '\)\@!',
      \ '(?>':  '\)\@>',
      \ '(?:':  '\)',
      \ '(?|':  '\)',
      \ '(':    '\)',
      \}
let s:metachar2set_content = {
      \ '\s': ' \t',
      \ '\w': '0-9a-zA-Z_',
      \ '\d': '0-9',
      \ '\h': '0-9a-fA-F',
      \ '\R': '',
      \ '\n': '',
      \ '\v': '',
      \ '\f': '',
      \ '\r': '',
      \ '\o': '\o',
      \ '\u': '\u',
      \ '\x': '\x',
      \ '\]': '\]',
      \ '\[': '\[',
      \}
let s:posix_set2set_content = {
      \ '[:word:]':  s:metachar2set_content['\w'],
      \ '[:ascii:]': '\x00-\x7F',
      \}

fu! s:PCRE2Vim.pop_context() abort dict
  call remove(self.contexts, -1)
endfu

fu! s:PCRE2Vim.push_context(label) abort dict
  let self.contexts += [{ 'label': a:label, 'start': self.p }]
endfu

fu! s:PCRE2Vim.parse_set() abort dict
  let result = [self.advance().matched_text]

  while ! self.end()
    if self.next_is([s:SET_START])
      let result += [self.advance().matched_text]
    elseif self.next_is([s:BRACKETED_ESCAPE])
      let result += [substitute(self.advance().matched_text, '[{}]', '', 'g')]
    elseif self.next_is([s:PROPERTY])
      call self.throw('properties are not supported')
    elseif self.next_is([s:POSIX_NAMED_SET])
      let text = self.advance().matched_text
      let result += [get(s:posix_set2set_content, text, text)]
    elseif self.next_is([s:ESCAPED_ANY])
      let text = self.advance().matched_text
      let result += [get(s:metachar2set_content, text, text[1:])]
    elseif self.next_is([s:SET_END])
      call self.advance()
      if self.contexts[-1].label ==# s:SET_START | return result + [']'] | endif

      let self.result += result
      call self.throw('unexpected context' . string(self.contexts))
    else
      let result += [self.advance().matched_text]
    endif
  endwhile

  let self.result += result
  call self.throw('unexpected EOF (SET_END is missing)')
endfu

fu! s:PCRE2Vim.set_global_modifiers(matched_text) abort dict
  " Only case insensitive match modifier is supported.
  " There are some false positives are possible if a pattern heavily relies on
  " case matching.
  if self.case_sensitive && a:matched_text =~#  '[^-]i'
    let self.result += ['\c']
  endif
endfu

fu! s:PCRE2Vim.convert() abort dict
  while ! self.end()
    if self.next_is([s:ANY])
      call self.advance()
      let self.result += [get(s:pcre2vim_escape, self.token.matched_text, self.token.matched_text)]
    elseif self.next_is([s:QUANTIFIER])
      let self.result += [s:pcre2vim_quantifier[self.advance().matched_text]]
    elseif self.next_is([s:ESCAPED_ANY])
      call self.advance()
      let self.result += [get(s:pcre2vim_expand_escaped, self.token.matched_text, self.token.matched_text)]
    elseif self.next_is([s:SET_START])
      call self.push_context(s:SET_START)
      let self.result += self.parse_set()
      call self.pop_context()
    elseif self.next_is([s:GROUP_START])
      call self.advance()
      let self.result += [s:pcre2vim_group_start[self.token.matched_text]]
      call self.push_context(self.token.matched_text)
    elseif self.next_is([s:GROUP_END])
      call self.advance()
      if empty(self.contexts) | call self.throw('unexpected GROUP_END') | endif

      if has_key(s:pcre2vim_group_end, self.contexts[-1].label)
        let self.result += [s:pcre2vim_group_end[self.contexts[-1].label]]
      elseif self.contexts[-1].label ==# s:MODIFIER_SPAN
        " just pop the context
      else
        throw 'Unknown group ending encountered: ' . string(self.contexts[-1].label)
      endif
      call self.pop_context()
    elseif self.next_is([s:RANGE_QUANTIFER])
      call self.advance()
      let range = matchstr(self.token.matched_text, s:capture_range_quantifier)
      if self.token.matched_text =~#  '?$'
        let self.result += ['\{-'.range.'}']
      else
        let self.result += ['\{'.range.'}']
      endif
    elseif self.next_is([s:BRACKETED_ESCAPE])
      let self.result += [substitute(self.advance().matched_text, '[{}]', '', 'g')]
    elseif self.next_is([s:MODIFIER])
      call self.advance()
      call self.set_global_modifiers(self.token.matched_text)
    elseif self.next_is([s:MODIFIER_SPAN])
      call self.advance()
      call self.set_global_modifiers(self.token.matched_text)
      call self.push_context(s:MODIFIER_SPAN)
    elseif self.next_is([s:NAMED_GROUP_START])
      call self.advance()
      let self.result += ['\(']
      call self.push_context('(')
    elseif self.next_is([s:COMMENT])
      call self.advance()
    elseif self.next_is([s:PROPERTY])
      call self.throw('properties are not supported')
    else
      let self.result += [self.advance().matched_text]
    endif
  endwhile

  if !empty(self.contexts)
    call self.throw('unexpected EOF (GROUP_END is missing)')
  endif

  return self.result
endfu

if g:esearch#env is# 0
  fu! s:PCRE2Vim.throw(msg) abort dict
    throw 'PCRE2Vim: ' . a:msg . ', at col ' . string(self.p)
  endfu
else
  fu! s:PCRE2Vim.throw(msg) abort dict
    throw 'PCRE2Vim: ' . a:msg . '. Token: ' . string(self.token) . ', at col ' . string(self.p)
  endfu
endif

fu! s:PCRE2Vim.advance() abort dict
  let self.token = self.consume()
  let self.p  += strchars(self.token.matched_text)
  return self.token
endfu
