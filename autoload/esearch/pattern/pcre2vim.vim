let s:Message = esearch#message#import()
let s:Lexer   = vital#esearch#import('Text.Lexer')
let s:Parser  = vital#esearch#import('Text.Parser')

" NOTE: is not intended to be a general purpose converter as some of atoms are
" suppressed for using in #out#win

fu! esearch#pattern#pcre2vim#convert(string, ...) abort
  try
    let tokens = s:PCRE2Vim.new(a:string).convert()
  catch /^PCRE2Vim:/
    call s:Message.warn(printf("Can't convert %s to vim regex dialect for matches highlight (reason: %s)",
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
let s:match_modifiers_span = printf('(?%s:', s:modifiers_set)
let s:match_modifiers      = printf('(?%s)', s:modifiers_set)
unlet s:modifiers_set
let s:match_posix_bracket_exp = join([
      \ 'alnum',
      \ 'alpha',
      \ 'blank',
      \ 'cntrl',
      \ 'digit',
      \ 'graph',
      \ 'lower',
      \ 'print',
      \ 'punct',
      \ 'space',
      \ 'upper',
      \ 'xdigit',
      \ 'return',
      \ 'tab',
      \ 'escape',
      \ 'backspace',
      \ 'word',
      \ 'ascii',
      \ ], '\|')
let s:match_posix_bracket_exp = printf('\[:\%(%s\):\]', s:match_posix_bracket_exp)
let s:match_range_quantifier   = '{\%(\d\+\|\d\+,\d*\)}[+?]\='
let s:capture_range_quantifier = '{\zs\%(\d\+\|\d\+,\d*\)\ze}[+?]\='
" Very rough match
let s:match_bracketed_escape = '\%(\\[xou]{\x\{,4}}\)'
let s:rules = [
      \  ['POSIX_BRACKET_EXP',        s:match_posix_bracket_exp                ],
      \  ['CLASS_START',              '\['                                     ],
      \  ['NCLASS_START',             '\[\^'                                   ],
      \  ['CLASS_END',                '\]'                                     ],
      \  ['MODIFIER',                 s:match_modifiers                        ],
      \  ['MODIFIER_SPAN',            s:match_modifiers_span                   ],
      \  ['POSITIVE_LOOKBEHIND',      '(?<='                                   ],
      \  ['NEGATIVE_LOOKBEHIND',      '(?<!'                                   ],
      \  ['POSITIVE_LOOKAHEAD',       '(?='                                    ],
      \  ['NEGATIVE_LOOKAHEAD',       '(?!'                                    ],
      \  ['ATOMIC_GROUP',             '(?>'                                    ],
      \  ['NONCAPTURING_GROUP_START', '(?:'                                    ],
      \  ['NAMED_GROUP_START',        '(?\%(P\=<\w\+>\|''\w\+''\)'             ],
      \  ['BRANCH_RESET_START',       '(?|'                                    ],
      \  ['GROUP_START',              '('                                      ],
      \  ['GROUP_END',                ')'                                      ],
      \  ['SUBJECT_BOUNDARY',         '\\[AzZ]'                                ],
      \  ['RANGE_QUANTIFER',          s:match_range_quantifier                 ],
      \  ['QUANTIFIER',               '\%(??\|\*?\|+?\|?+\|\*+\|++\|?\|+\|\*\)'],
      \  ['WORD_BOUNDARY',            '\\[Bb]'                                 ],
      \  ['TOBEESCAPED',              '[|~]'                                   ],
      \  ['TOBEUNESCAPED',            '\\[&{%<>()?+|=@_]'                      ],
      \  ['PROPERTY',                 '\\[Pp]{\w\+}'                           ],
      \  ['BRACKETED_ESCAPE',         s:match_bracketed_escape                 ],
      \  ['ESCAPED_ANY',              '\\.'                                    ],
      \  ['ANy',                      '.'                                      ],
      \]
let s:pcre2vim_subject_boundary = {
      \ '\A': '^',
      \ '\z': '$',
      \ '\Z': '$',
      \}
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
      \ }
let s:vim_group_close = {
      \ 'POSITIVE_LOOKBEHIND': '\)\@<=',
      \ 'NEGATIVE_LOOKBEHIND': '\)\@<!',
      \ 'POSITIVE_LOOKAHEAD':  '\)\@=',
      \ 'NEGATIVE_LOOKAHEAD':  '\)\@!',
      \ 'GROUP_START':         '\)',
      \ 'ATOMIC_GROUP':        '\)\@>',
      \}
let s:metachar2class_content = {
      \ '\s': ' \t',
      \ '\w': '0-9a-zA-Z_',
      \ '\d': '0-9',
      \ '\h': '0-9a-fA-F',
      \ '\R': '',
      \ '\n': '',
      \ '\v': '',
      \ '\f': '',
      \ '\r': '', 
      \ }

fu! s:PCRE2Vim.pop_context() abort dict
  call remove(self.contexts, -1)
endfu

fu! s:PCRE2Vim.push_context(label) abort dict
  let self.contexts += [{ 'label': a:label, 'start': self.p }]
endfu

fu! s:PCRE2Vim.parse_class() abort dict
  let result = [self.advance().matched_text]

  while ! self.end()
    if self.next_is(['SIMPLE_RANGE'])
      let result += [self.advance().matched_text]
    elseif self.next_is(['CLASS_START'])
      let result += [self.advance().matched_text]
    elseif self.next_is(['BRACKETED_ESCAPE'])
      let result += [substitute(self.advance().matched_text, '[{}]', '', 'g')]
    elseif self.next_is(['PROPERTY'])
      call self.throw('properties are not supported')
    elseif self.next_is(['TOBEUNESCAPED'])
      call self.advance()
      let result += [self.token.matched_text[1:]]
    elseif self.next_is(['POSIX_BRACKET_EXP'])
      let text = self.advance().matched_text
      if text ==# '[:word:]'
        let result += [s:metachar2class_content['\w']]
      elseif text ==# '[:ascii:]'
        let result += ['\x00-\x7F']
      else
        let result += [self.token.matched_text]
      endif
    elseif self.next_is(['ESCAPED_ANY'])
      let text = self.advance().matched_text
      let result += [get(s:metachar2class_content, text, text)]
    elseif self.next_is(['CLASS_END'])
      call self.advance()
      if self.contexts[-1].label ==# 'CLASS'
        return result + [']']
      else
        let self.result += result
        call self.throw('unexpected context' . string(self.contexts))
      endif
    else
      let result += [self.advance().matched_text]
    endif
  endwhile

  let self.result += result
  call self.throw('unexpected EOF (CLASS_END is missing)')
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
    if self.next_is(['POSITIVE_LOOKBEHIND', 'POSITIVE_LOOKAHEAD', 'NEGATIVE_LOOKAHEAD', 'NEGATIVE_LOOKBEHIND', 'ATOMIC_GROUP'])
      call self.advance()
      let self.result += ['\%(']
      call self.push_context(self.token.label)
    elseif self.next_is(['MODIFIER_SPAN'])
      call self.advance()
      call self.set_global_modifiers(self.token.matched_text)
      call self.push_context('MODIFIER_SPAN')
    elseif self.next_is(['MODIFIER'])
      call self.advance()
      call self.set_global_modifiers(self.token.matched_text)
    elseif self.next_is(['RANGE_QUANTIFER'])
      call self.advance()
      let range = matchstr(self.token.matched_text, s:capture_range_quantifier)
      if self.token.matched_text =~#  '?$'
        let self.result += ['\{-'.range.'}']
      else
        let self.result += ['\{'.range.'}']
      endif
    elseif self.next_is(['BRACKETED_ESCAPE'])
      let self.result += [substitute(self.advance().matched_text, '[{}]', '', 'g')]
    elseif self.next_is(['PROPERTY'])
      call self.throw('properties are not supported')
    elseif self.next_is(['TOBEESCAPED'])
      call self.advance()
      let self.result += ['\'.self.token.matched_text]
    elseif self.next_is(['TOBEUNESCAPED'])
      call self.advance()
      let self.result += [self.token.matched_text[1:]]
    elseif self.next_is(['WORD_BOUNDARY'])
      if self.advance().matched_text ==# '\b'
        let self.result += ['\%(\<\|\>\)']
      else " ==# '\B'
        let self.result += ['\%(\w\)\@<=\%(\w\)\@='] " lookahead + lookbehind
      endif
    elseif self.next_is(['SUBJECT_BOUNDARY'])
      let self.result += [s:pcre2vim_subject_boundary[self.advance().matched_text]]
    elseif self.next_is(['NONCAPTURING_GROUP_START'])
      call self.advance()
      let self.result += ['\%(']
      call self.push_context('GROUP_START')
    elseif self.next_is(['NAMED_GROUP_START'])
      call self.advance()
      let self.result += ['\(']
      call self.push_context('GROUP_START')
    elseif self.next_is(['BRANCH_RESET_START'])
      call self.advance()
      call self.warn('branch reset is not supported in vim')
      let self.result += ['\(']
      call self.push_context('GROUP_START')
    elseif self.next_is(['GROUP_START'])
      call self.advance()
      let self.result += ['\(']
      call self.push_context('GROUP_START')
    elseif self.next_is(['NCLASS_START', 'CLASS_START'])
      call self.push_context('CLASS')
      let self.result += self.parse_class()
      call self.pop_context()
    elseif self.next_is(['QUANTIFIER'])
      let self.result += [s:pcre2vim_quantifier[self.advance().matched_text]]
    elseif self.next_is(['GROUP_END'])
      call self.advance()
      if empty(self.contexts) | call self.throw('unexpected group end') | endif

      if has_key(s:vim_group_close, self.contexts[-1].label)
        let self.result += [s:vim_group_close[self.contexts[-1].label]]
      elseif self.contexts[-1].label ==# 'MODIFIER_SPAN'
        " just pop the context
      else
        throw 'Unknown group ending encountered: ' . string(self.contexts[-1].label)
      endif
      call self.pop_context()
    else
      let self.result += [self.advance().matched_text]
    endif
  endwhile

  if !empty(self.contexts)
    call self.throw('unexpected EOF (GROUP_END is missing)')
  endif

  return self.result
endfu

fu! s:PCRE2Vim.warn(msg) abort dict
  echomsg a:msg
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
