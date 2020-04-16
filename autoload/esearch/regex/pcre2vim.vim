let s:Vital        = vital#esearch#new()
let s:LexerModule  = s:Vital.import('Text.Lexer')
let s:ParserModule = s:Vital.import('Text.Parser')

fu! esearch#regex#pcre2vim#convert(string, ...) abort
  try
    let parsed = s:PCRE2Vim.new(a:string).parse()
  catch /^PCRE2Vim:/
    return ''
  endtry
  return join(parsed, '')
endfu

" https://www.regular-expressions.info/modifiers.html
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

let s:PCRE2Vim = {
      \ 'case_sensitive':       1,
      \ 'contexts':             [],
      \ '_debug_tokens':        [],
      \ 'result':               [],
      \ 'p':                    0,
      \ }

fu s:PCRE2Vim.new(text) abort dict
  let lexer = s:LexerModule.lexer(s:rules).exec(a:text)
  let instance = extend(s:ParserModule.parser().exec(lexer), deepcopy(self))
  let instance.text = a:text
  return instance
endfu

let s:rules = [
      \  ['POSIX_BRACKET_EXP',        s:match_posix_bracket_exp                ],
      \  ['CLASS_START',              '\['                                     ],
      \  ['NCLASS_START',             '\[\^'                                   ],
      \  ['CLASS_END',                '\]'                                     ],
      \  ['ESCAPED_CLASS_START',      '\\\['                                   ],
      \  ['ESCAPED_CLASS_END',        '\\\]'                                   ],
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
      \  ['SUBJECT_START',            '\\A'                                    ],
      \  ['SUBJECT_END',              '\\[zZ]'                                 ],
      \  ['RANGE_QUANTIFER',          s:match_range_quantifier                 ],
      \  ['QUANTIFIER',               '\%(??\|\*?\|+?\|?+\|\*+\|++\|?\|+\|\*\)'],
      \  ['DOUBLE_SLASH',             '\\\\'                                   ],
      \  ['WORD_BOUNDARY',            '\\b'                                    ],
      \  ['TOBEESCAPED',              '[|~]'                                   ],
      \  ['TOBEUNESCAPED',            '\\[&{%<>()?+|=@_]'                      ],
      \  ['BRACKETED_ESCAPE',         s:match_bracketed_escape                 ],
      \  ['DOT',                      '\.'                                     ],
      \  ['ESCAPED_ANY',              '\\.'                                    ],
      \  ['ANy',                      '.'                                      ],
      \]

let s:subject_start = '^'
let s:subject_end   = '$'
" NOTE: possessive are converted to greedy. https://github.com/vim/vim/issues/4638
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

fu! s:split_modifiers(modifiers)
  return split(a:modifiers, '-\=\w\zs')
endfu

fu! s:PCRE2Vim.parse_class() abort dict
  while ! self.end()
    if self.next_is(['SIMPLE_RANGE'])
      let self.result += [self.advance().matched_text]
    elseif self.next_is(['CLASS_START'])
      call self.fail('unexpected CLASS_START')
    elseif self.next_is(['BRACKETED_ESCAPE'])
      let self.result += [substitute(self.advance().matched_text, '[{}]', '', 'g')]
    elseif self.next_is(['TOBEUNESCAPED'])
      call self.advance()
      let self.result += [self.token.matched_text[1:]]
    elseif self.next_is(['POSIX_BRACKET_EXP'])
      call self.advance()
      let text = self.token.matched_text
      if text ==# '[:word:]'
        let self.result += [s:metachar2class_content['\w']]
      elseif text ==# '[:ascii:]'
        let self.result += ['\x00-\x7F']
      else
        let self.result += [self.token.matched_text]
      endif
    elseif self.next_is(['ESCAPED_ANY'])
      call self.advance()
      let text = self.token.matched_text
      if has_key(s:metachar2class_content, text)
        let self.result += [s:metachar2class_content[text]]
      else
        let self.result += [text]
      endif
    elseif self.next_is(['CLASS_END'])
      call self.advance()
      if self.contexts[-1].label ==# 'CLASS'
        call self.pop_context()
        let self.result += [']']
        return self.result
      else
        call self.fail('unexpected context' . string(self.contexts))
      endif
    else
      let self.result += [self.advance().matched_text]
    endif
  endwhile

  return self.fail('unexpected EOF (CLASS_END expected)')
endfu

fu! s:PCRE2Vim.set_global_modifiers(matched_text) abort dict
  " Only case insensitive match modifier is supported.
  " There are some false positives are possible if a pattern heavily relies on
  " case matching.
  if self.case_sensitive && a:matched_text =~# '[^-]i'
    let self.result += ['\c']
  endif
endfu

fu! s:PCRE2Vim.parse() abort dict
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
      if self.token.matched_text =~# '?$'
        let self.result += ['\{-'.range.'}']
      else
        let self.result += ['\{'.range.'}']
      endif
    elseif self.next_is(['BRACKETED_ESCAPE'])
      let self.result += [substitute(self.advance().matched_text, '[{}]', '', 'g')]
    elseif self.next_is(['TOBEESCAPED'])
      call self.advance()
      let self.result += ['\'.self.token.matched_text]
    elseif self.next_is(['TOBEUNESCAPED'])
      call self.advance()
      let self.result += [self.token.matched_text[1:]]
    elseif self.next_is(['WORD_BOUNDARY'])
      let self.result += ['\%(\<\|\>\)']
      call self.advance()
    elseif self.next_is(['SUBJECT_START'])
      call self.advance()
      let self.result += [s:subject_start]
    elseif self.next_is(['SUBJECT_END'])
      call self.advance()
      let self.result += [s:subject_end]
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
      let self.result += [self.advance().matched_text]
      call self.push_context('CLASS')
      call self.parse_class()
    elseif self.next_is(['QUANTIFIER'])
      let self.result += [s:pcre2vim_quantifier[self.advance().matched_text]]
    elseif self.next_is(['DOUBLE_SLASH'])
      " is it a hack?
      call self.advance()
      let self.result += ['\\']
    elseif self.next_is(['DOT'])
      call self.advance()
      let self.result += ['.']
    elseif self.next_is(['GROUP_END'])
      call self.advance()
      if empty(self.contexts) | call self.fail('Unexpected group end') | endif

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
    call self.fail('Unmatched group found')
  endif

  return self.result
endfu

fu! s:PCRE2Vim.debug() abort dict
  let output = []
  for t in self._debug_tokens

    let location = self.text[max([0, t.p - 5]) : min([len(self.text), t.p + 5])]
    call add(output,
          \ printf('%15s | %3d | %30s | %4s | %10s', t.context.label, t.p, t.token.label, t.token.matched_text, string(location))
          \ )
  endfor

  return join(output, "\n")
endfu

fu! s:PCRE2Vim.warn(msg) abort dict
  echomsg a:msg
endfu

fu! s:PCRE2Vim.fail(msg) abort dict
  throw 'PCRE2Vim:' . a:msg . '. Token: ' . string(self.token) . ' at ' . string(self.p)
endfu

fu! s:PCRE2Vim.advance() abort dict
  let self.token = self.consume()
  let self.p  += strchars(self.token.matched_text)
  if g:esearch#env isnot 0
    let self._debug_tokens += [{'token': deepcopy(self.token), 'p': self.p, 'context': get(self.contexts, -1, {'label': 'none'}) }]
  endif
  return self.token
endfu
