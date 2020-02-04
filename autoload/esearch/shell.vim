let s:V = vital#esearch#new()
let s:L = s:V.import('Text.Lexer')
let s:P = s:V.import('Text.Parser')

let s:rules = [
      \ [ 'DQ',                '"'    ],
      \ [ 'SQ',                "'"    ],
      \ [ 'ESCAPED_DQ',        '\\"'  ],
      \ [ 'ESCAPED_SQ',        '\\''' ],
      \ [ 'TRAILING_ESCAPE',   '\\$'  ],
      \ [ 'WS',                '\s\+' ],
      \ [ 'ESCAPED_ANY',       '\\.'  ],
      \ [ 'ANy',               '.'    ],
      \ ]

let g:asd = []
fu! s:consume_squote() dict abort
  let parsed = ''
  let start = self.p
  call self.advance()

  while ! self.end()
    if self.next_is(['SQ'])
      call self.advance()
      return s:word(parsed, start, self.p)
    elseif self.next_is(['ESCAPED_SQ'])
      call self.advance()
      return s:word(parsed.'\', start, self.p)
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  let self.error = 'unterminated single quote'
  return s:null_word
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
      return s:word(parsed, start, self.p)
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  let self.error = 'unterminated double quote'
  return s:null_word
endfu

fu! s:consume_word() abort dict
  let parsed = ''
  let start = self.p

  while ! self.end()
    if self.next_is(['ESCAPED_SQ', 'ESCAPED_DQ', 'ESCAPED_ANY'])
      let parsed .= self.advance().matched_text[1]
    elseif self.next_is(['DQ'])
      let parsed .= self.consume_dquote().word
    elseif self.next_is(['SQ'])
      let parsed .= self.consume_squote().word
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

  return s:word(parsed, start, self.p)
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

fu! s:word(word, start, end) abort
  return {'word': a:word, 'start': a:start, 'end': a:end}
endfu
let s:null_word = s:word(0,0,0)

let s:functions = {
      \ 'parse':  function('s:parse'),
      \ 'consume_squote': function('s:consume_squote'),
      \ 'consume_dquote': function('s:consume_dquote'),
      \ 'consume_word':   function('s:consume_word'),
      \ 'advance':        function('s:advance'),
      \ 'error':  0,
      \ 'p':      0,
      \ }

fu! esearch#shell#split(string) abort
  let lexer = s:L.lexer(s:rules).exec(a:string)
  let parser = s:P.parser().exec(lexer)
  call extend(parser, s:functions)

  let words = parser.parse()
  return { 'words': words, 'error': parser.error }
endfu
