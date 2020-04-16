let s:Vital        = vital#esearch#new()
let s:LexerModule  = s:Vital.import('Text.Lexer')
let s:ParserModule = s:Vital.import('Text.Parser')

fu! esearch#regex#pcre2vim#convert(string, ...) abort
  let parsed = s:PCRE2Vim.new(a:string).parse()
  return join(parsed, '')
endfu

let s:PCRE2Vim = {
      \ 'global_context':       { 'modifiers': [] },
      \ 'global_modifiers':     [],
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

let s:dotall = '.'
let s:pcre2vim_modifier = {
      \ 'i':  '\c',
      \ '-i': '\C',
      \ 'm':  '',
      \ '-m': '',
      \ }
let s:pcre2vim_lazy_quantifier = {
      \ '??': '\{-,1}',
      \ '*?': '\{-}',
      \ '+?': '\{-1,}',
      \ }

" TODO ESCAPED_CLASS_START and ESCAPED_CLASS_END are actually hacks
let s:rules = [
      \ [ 'POSIX_BRACKET_EXP',        '\[:\%(alnum\|alpha\|blank\|cntrl\|digit\|graph\|lower\|print\|punct\|space\|upper\|xdigit\|return\|tab\|escape\|backspace\|word\|ascii\):\]'],
      \ [ 'HEX',                      '\%(\\x\x\{2}\|\\x\x\{4}\|\\x{\x\{2}}\|\\x{\x\{4}}\)'  ],
      \ [ 'CLASS_START',              '\['                         ],
      \ [ 'NCLASS_START',             '\[\^'                       ],
      \ [ 'CLASS_END',                '\]'                         ],
      \ [ 'ESCAPED_CLASS_START',      '\\\['                       ],
      \ [ 'ESCAPED_CLASS_END',        '\\\]'                       ],
      \ [ 'MODIFIER',                 '(?[mi\-]\+)'                ],
      \ [ 'MODIFIER_SPAN',            '(?[mi\-]\+:'                ],
      \ [ 'POSITIVE_LOOKBEHIND',      '(?<='                       ],
      \ [ 'NEGATIVE_LOOKBEHIND',      '(?<!'                       ],
      \ [ 'POSITIVE_LOOKAHEAD',       '(?='                        ],
      \ [ 'NEGATIVE_LOOKAHEAD',       '(?!'                        ],
      \ [ 'ATOMIC_GROUP',             '(?>'                        ],
      \ [ 'NONCAPTURING_GROUP_START', '(?:'                        ],
      \ [ 'NAMED_GROUP_START',        '(?\%(P\=<\w\+>\|''\w\+''\)' ],
      \ [ 'BRANCH_RESET_START',       '(?|'                        ],
      \ [ 'GROUP_START',              '('                          ],
      \ [ 'GROUP_END',                ')'                          ],
      \ [ 'SUBJECT_START',            '\\A'                        ],
      \ [ 'SUBJECT_END',              '\\z'                        ],
      \ [ 'RANGE_QUANTIFER',          '{\%(-\|-\=\d\+,\=\d*\)}?\=' ],
      \ [ 'LAZY_QUANTIFIER',          '\%(??\|\*?\|+?\)'           ],
      \ [ 'GREEDY_QUANTIFIER',        '?'                          ],
      \ [ 'DOUBLE_SLASH',             '\\\\'                       ],
      \ [ 'WORD_BOUNDARY',            '\\b'                        ],
      \ [ 'TOBEESCAPED',              '[+|~]'                      ],
      \ [ 'TOBEUNESCAPED',            '\\[()?+|]'                  ],
      \ [ 'DOT',                      '\.'                         ],
      \ [ 'ESCAPED_ANY',              '\\.'                        ],
      \ [ 'ANy',                      '.'                          ],
      \                                                            ]

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

fu! s:PCRE2Vim.push_context(label, modifiers) abort dict
  let self.contexts += [{ 'label': a:label, 'modifiers': a:modifiers, 'start': self.p }]
endfu

fu! s:PCRE2Vim.current_modifiers() abort dict
  let current_modifiers = deepcopy(self.global_modifiers)
  if !empty(self.contexts)
    let current_modifiers = s:merge_modifiers(current_modifiers, self.contexts[-1].modifiers)
  endif
  return current_modifiers
endfu

fu! s:PCRE2Vim.active_modifier(name) abort dict
  let is_present_globally = index(self.global_modifiers, a:name) >= 0
  if empty(self.contexts)
    return is_present_globally
  else
    return is_present_globally || index(self.contexts[-1].modifiers, a:name) >= 0
  endif
endfu

fu! s:PCRE2Vim.parse_class() abort dict
  while ! self.end()
    if self.next_is(['SIMPLE_RANGE'])
      let self.result += [self.advance().matched_text]
    elseif self.next_is(['CLASS_START'])
      call self.fail('unexpected CLASS_START')
    elseif self.next_is(['HEX'])
      let self.result += [substitute(self.advance().matched_text, '[{}]', '', 'g')]
    elseif self.next_is(['TOBEUNESCAPED'])
      call self.advance()
      let self.result += [self.token.matched_text[1:]]
    elseif self.next_is(['POSIX_BRACKET_EXP'])
      call self.advance()
      let t = self.token.matched_text
      if t ==# '[:word:]'
        let self.result += [s:metachar2class_content['\w']]
      elseif t ==# '[:ascii:]'
        let self.result += ['\x00-\x7F']
      else
        let self.result += [self.token.matched_text]
      endif
    elseif self.next_is(['ESCAPED_ANY'])
      call self.advance()
      let t = self.token.matched_text
      if has_key(s:metachar2class_content, t)
        let self.result += [s:metachar2class_content[t]]
        " call self.warn('unknown escape encountered: ' . t)
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

fu! s:split_modifiers(modifiers)
  return split(a:modifiers, '-\=\w\zs')
endfu

fu! s:merge_modifiers(mergeable, merged) abort
  let result = []
  let [mergeable, merged] = [deepcopy(a:mergeable), deepcopy(a:merged)]

  for m2 in merged
    if m2[0] ==# '-' && index(mergeable, m2[1]) >=0
      call remove(mergeable, m2[1])
      continue
    endif

    call add(mergeable, m2)
  endfor
  call uniq(mergeable)
  return mergeable
endfu

fu! s:PCRE2Vim.parse() abort dict
  while ! self.end()
    if self.next_is(['POSITIVE_LOOKBEHIND', 'POSITIVE_LOOKAHEAD', 'NEGATIVE_LOOKAHEAD', 'NEGATIVE_LOOKBEHIND', 'ATOMIC_GROUP'])
      call self.advance()
      let self.result += ['\%(']
      call self.push_context(self.token.label, [])

    elseif self.next_is(['MODIFIER_SPAN'])
      call self.advance()
      let modifier = matchstr(self.token.matched_text, '(?\zs\%([mi]\|-[mi]\)\ze:')
      let self.result += [s:pcre2vim_modifier[modifier]]
      call self.push_context('MODIFIER_SPAN', s:merge_modifiers(self.current_modifiers(), [modifier]))
    elseif self.next_is(['RANGE_QUANTIFER'])
      call self.advance()
      let m = matchlist(self.token.matched_text, '{\(\d*\)\(,\)\=\(\d*\)}\(?\=\)')[0:4]
      if self.token.matched_text =~# '?$'
        let self.result += ['\{-'.join(m[1:3], '').'}']
      else
        let self.result += ['\{'.join(m[1:3], '').'}']
      endif
    elseif self.next_is(['HEX'])
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
      let self.result += ['\%^']
    elseif self.next_is(['MODIFIER'])
      call self.advance()
      let modifiers = matchstr(self.token.matched_text, '(?\zs\([im]\|-[im]\)\+\ze)')
      call self.set_global_modifiers([modifiers])
      let self.result += [s:pcre2vim_modifier[modifiers]]
    elseif self.next_is(['SUBJECT_END'])
      call self.advance()
      let self.result += ['\%$']
    elseif self.next_is(['NONCAPTURING_GROUP_START'])
      call self.advance()
      let self.result += ['\%(']
      call self.push_context('GROUP_START', [])
    elseif self.next_is(['NAMED_GROUP_START'])
      call self.advance()
      let self.result += ['\(']
      call self.push_context('GROUP_START', [])
    elseif self.next_is(['BRANCH_RESET_START'])
      call self.advance()
      call self.warn('branch reset is not supported in vim')
      let self.result += ['\(']
      call self.push_context('GROUP_START', [])
    elseif self.next_is(['GROUP_START'])
      call self.advance()
      let self.result += ['\(']
      call self.push_context('GROUP_START', [])
    elseif self.next_is(['NCLASS_START', 'CLASS_START'])
      let self.result += [self.advance().matched_text]
      call self.push_context('CLASS', [])
      call self.parse_class()
    elseif self.next_is(['LAZY_QUANTIFIER'])
      let self.result += [s:pcre2vim_lazy_quantifier[self.advance().matched_text]]
    elseif self.next_is(['DOUBLE_SLASH'])
      " is it a hack?
      call self.advance()
      let self.result += ['\\']
    elseif self.next_is(['GREEDY_QUANTIFIER'])
      call self.advance()
      let self.result += ['\=']
    elseif self.next_is(['DOT'])
      call self.advance()

      if self.active_modifier('m')
        let self.result += [s:dotall]
      else
        let self.result += ['.']
      endif
    elseif self.next_is(['GROUP_END'])
      if empty(self.contexts)
        call self.fail('Unexpected group ending')
      endif

      if has_key(s:vim_group_close, self.contexts[-1].label)
        let self.result += [s:vim_group_close[self.contexts[-1].label]]
      elseif self.contexts[-1].label ==# 'MODIFIER_SPAN'
        " just pop the context
      else
        throw 'Unknown group ending encountered: ' . string(self.contexts[-1].label)
      endif

      call self.advance()
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

fu! s:PCRE2Vim.set_global_modifiers(modifiers) abort dict
  for m in a:modifiers
    if m[0] ==# '-'
      if index(self.global_modifiers, m[1]) >=0
        " TODO Warning
        call remove(self.global_modifiers, index(self.global_modifiers, m[1]))
      endif
    else
      let self.global_modifiers = s:merge_modifiers(self.global_modifiers, [ m ])
    endif
  endfor
endfu

fu! s:PCRE2Vim.warn(msg) abort dict
  echomsg a:msg
endfu

fu! s:PCRE2Vim.fail(msg) abort dict
  throw 'Parser:' . a:msg . '. Token: ' . string(self.token) . ' at ' . string(self.p)
endfu

fu! s:PCRE2Vim.advance() abort dict
  let self.token = self.consume()
  let self.p  += strchars(self.token.matched_text)
  if g:esearch#env isnot 0
    let self._debug_tokens += [{'token': deepcopy(self.token), 'p': self.p, 'context': get(self.contexts, -1, {'label': 'none'}) }]
  endif
  return self.token
endfu
