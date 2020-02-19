let s:Vital        = vital#esearch#new()
let s:LexerModule  = s:Vital.import('Text.Lexer')
let s:ParserModule = s:Vital.import('Text.Parser')
let s:escape = '^]@()}'

fu! esearch#shell#split(string, ...) abort
  let options = empty(a:000) ? s:default_options : extend(deepcopy(a:1), s:default_options)
  let lexer = s:LexerModule.lexer(s:rules).exec(a:string)
  let parser = s:ParserModule.parser().exec(lexer)
  call extend(parser, s:parser_methods)
  call extend(parser, options)

  let parsed = parser.split()

  let paths = []
  let metadata = []
  for word in parsed
    call add(paths, copy(word.text))
    unlet word.text
    call add(metadata, word)
  endfor

  return [paths, metadata, parser.error]
endfu

fu! esearch#shell#fnamesescape_and_join(paths, metadata, ...) abort
  let separator = a:0 == 0 ? ' ' : a:1
  if empty(a:metadata)
    return join(map(copy(a:paths), 'fnameescape(v:val)'), separator)
  endif

  let paths = deepcopy(a:paths)
  let escaped = []
  for i in range(0, len(paths)-1)
    call add(escaped, esearch#shell#fnameescape(paths[i], a:metadata[i]))
  endfor

  let joined_paths = join(escaped, separator)
  return joined_paths
endfu

fu! esearch#shell#fnameescape(path, metadata) abort
  let wildcards = a:metadata.wildcards
  return join(esearch#shell#fnameescape_splitted(a:path, wildcards), '')

  return result
endfu

fu! esearch#shell#fnameescape_splitted(path, metadata) abort
  let wildcards = a:metadata
  let substr_begin = 0

  let parts = []
  for special_index in wildcards
    let parts += [
          \ escape(fnameescape(a:path[substr_begin : special_index][:-2]), s:escape),
          \ a:path[special_index]]
    let substr_begin = special_index + 1
  endfor
  let parts += [escape(fnameescape(a:path[substr_begin :]), s:escape)]

  return parts
endfu

let s:default_options = {}
let s:rules = [
      \ [ 'DQ',                '"'                 ],
      \ [ 'SQ',                "'"                 ],
      \ [ 'ESCAPED_DQ',        '\\"'               ],
      \ [ 'ESCAPED_SQ',        '\\'''              ],
      \ [ 'TRAILING_ESCAPE',   '\\$'               ],
      \ [ 'WS',                '\s\+'              ],
      \ [ 'ESCAPED_ANY',       '\\.'               ],
      \ [ 'SPECIAL',           '[?*+@!()|{}\[\^\]]'],
      \ [ 'ANy',               '.'                 ],
      \ ]

" let specials = '?*+@!()|{}[]^'
" let specials_list = split('?*+@!()|{}[]^', '\zs')

fu! s:consume_squote() dict abort
  let parsed = ''
  let start = self.p
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

  let self.error = 'unterminated single quote at column ' . start
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

  let self.error = 'unterminated double quote at column ' . start
  return ''
endfu

fu! s:consume_word() abort dict
  let parsed = ''
  let start = self.p
  let wildcards = []

  while ! self.end()
    if self.next_is(['ESCAPED_SQ', 'ESCAPED_DQ', 'ESCAPED_ANY'])
      let parsed .= self.advance().matched_text[1]
    elseif self.next_is(['DQ'])
      let parsed .= self.consume_dquote()
    elseif self.next_is(['SQ'])
      let parsed .= self.consume_squote()
    elseif self.next_is(['SPECIAL'])
      call add(wildcards, strchars(parsed))
      let parsed .= self.advance().matched_text
    elseif self.next_is(['WS'])
      break
    elseif self.next_is(['TRAILING_ESCAPE'])
      call self.advance()
      let self.error = 'trailing escape'
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  return s:word(parsed, start, self.p, wildcards)
endfu

function! s:split() abort dict
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

fu! s:word(text, start, end, wildcards) abort
  return {'text': a:text, 'start': a:start, 'end': a:end, 'wildcards': a:wildcards}
endfu

let s:parser_methods = {
      \ 'split':          function('s:split'),
      \ 'consume_squote': function('s:consume_squote'),
      \ 'consume_dquote': function('s:consume_dquote'),
      \ 'consume_word':   function('s:consume_word'),
      \ 'advance':        function('s:advance'),
      \ 'error':          0,
      \ 'p':              0,
      \ }
