let s:Vital        = vital#esearch#new()
let s:LexerModule  = s:Vital.import('Text.Lexer')
let s:ParserModule = s:Vital.import('Text.Parser')

fu! esearch#shell#split(string) abort
  let lexer = s:LexerModule.lexer(s:rules).exec(a:string)
  let parser = s:ParserModule.parser().exec(lexer)
  call extend(parser, (s:parser_methods))

  let parsed = parser.parse()

  let paths = []
  let metadata = []
  for word in parsed
    call add(paths, copy(word.text))
    unlet word.text
    call add(metadata, word)
  endfor

  return [paths, metadata, parser.error]
endfu

fu! esearch#shell#fnameescape(path, metadata) abort
  let parts = []
  let asterisks = a:metadata.asterisks
  let substring_start = 0

  for a in asterisks
    call add(parts, a:path[substring_start:a][:-2])
    let substring_start = a + 1
  endfor
  call add(parts, a:path[substring_start:])

  return join(map(parts, 'fnameescape(v:val)'), '*')
endfu

let s:rules = [
      \ [ 'DQ',                '"'    ],
      \ [ 'SQ',                "'"    ],
      \ [ 'ESCAPED_DQ',        '\\"'  ],
      \ [ 'ESCAPED_SQ',        '\\''' ],
      \ [ 'TRAILING_ESCAPE',   '\\$'  ],
      \ [ 'WS',                '\s\+' ],
      \ [ 'ESCAPED_ANY',       '\\.'  ],
      \ [ 'ASTERISK',          '\*'  ],
      \ [ 'ANy',               '.'    ],
      \ ]

fu! s:consume_squote() dict abort
  let parsed = ''
  call self.advance()

  while ! self.end()
    if self.next_is(['SQ'])
      call self.advance()
      return parsed
    elseif self.next_is(['ESCAPED_SQ'])
      call self.advance()
      return parsed.'\'
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  let self.error = 'unterminated single quote'
  return ''
endfu

fu! s:consume_dquote() dict abort
  let parsed = ''
  let start = self.p
  call self.advance()

  while ! self.end()
    if self.next_is(['ESCAPED_DQ', 'ESCAPED_ANY'])
      let parsed .= self.advance().matched_text[1]
    elseif self.next_is(['DQ'])
      let tok = self.advance()
      return parsed
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  let self.error = 'unterminated double quote'
  return ''
endfu

fu! s:consume_word() abort dict
  let parsed = ''
  let start = self.p
  let asterisks = []

  while ! self.end()
    if self.next_is(['ESCAPED_SQ', 'ESCAPED_DQ', 'ESCAPED_ANY'])
      let parsed .= self.advance().matched_text[1]
    elseif self.next_is(['DQ'])
      let parsed .= self.consume_dquote()
    elseif self.next_is(['SQ'])
      let parsed .= self.consume_squote()
    elseif self.next_is(['ASTERISK'])
      call add(asterisks, self.p)
      let parsed .= self.advance().matched_text
    elseif self.next_is(['WS'])
      break
      " let tok = self.advance()
    elseif self.next_is(['TRAILING_ESCAPE'])
      call self.advance()
      let self.error = 'no escaped character'
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  return s:word(parsed, start, self.p, asterisks)
endfu

function! s:parse() dict
  let words = []

  while ! self.end()
    if self.next_is(['WS'])
      call self.advance()
    else
      call add(words, self.consume_word())
    endif
  endwhile

  return words
endfunction

fu! s:advance() abort dict
  let token = self.consume()
  let self.p  += strchars(token.matched_text)

  return token
endfu

fu! s:word(text, start, end, asterisks) abort
  return {'text': a:text, 'start': a:start, 'end': a:end, 'asterisks': a:asterisks}
endfu

let s:parser_methods = {
      \ 'parse':          function('s:parse'),
      \ 'consume_squote': function('s:consume_squote'),
      \ 'consume_dquote': function('s:consume_dquote'),
      \ 'consume_word':   function('s:consume_word'),
      \ 'advance':        function('s:advance'),
      \ 'error':          0,
      \ 'p':              0,
      \ }
