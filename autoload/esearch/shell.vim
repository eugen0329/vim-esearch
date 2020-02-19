let s:Vital        = vital#esearch#new()
let s:LexerModule  = s:Vital.import('Text.Lexer')
let s:ParserModule = s:Vital.import('Text.Parser')

if !exists('g:esearch_shell_force_escaping_for')
  let g:esearch_shell_force_escaping_for = '^]@()}'
endif

" Returns splitted "shell words" from a string typed using shell syntax.
" Does:
"   - dequotation
"   - validation of missed closing quotes and trailing slashes
"   - finding unescaped special locations (for highlight and preserving from fnameescape)
"
" Validation of wildcards (closing braces etc.) is not performed to not mess
" with shell-specific syntaxes and configured options. User will be notified
" with a shell errors further anyway.
"
" Finding locations is required to tell the user (with a corresponding
" highlight) which characters will be used for globbing and to prevent escaping
" them with fnameescape. Escaping prevention is required to let builtin function
" do most of the job (internals of which depend on a platform and some other
" configurable options we don't want to deal with) while being able to specify paths
" which can be expanded by the shell.
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

" TODO rewrite matadata storage approach
fu! esearch#shell#fnameescape(path, ...) abort
  if a:0 == 1
    return join(esearch#shell#fnameescape_splitted(a:path, a:1), '')
  else
    return s:escape(a:path, g:esearch_shell_force_escaping_for)
  endif
endfu

" Returns escaped string parts, splitted by special characters as delimiters
" (with keeping them)
fu! esearch#shell#fnameescape_splitted(path, metadata) abort
  " These characters are not ecsaped by fnameescape. Escaping of them is required
  " to ensure consistency. It's done only within parts of a:path not marked by
  " the parser as special.
  let nonspecial_anymore = g:esearch_shell_force_escaping_for

  let parts = []
  let substr_begin = 0
  for special_index in a:metadata.wildcards
    let parts += [
          \ s:escape(a:path[substr_begin : special_index][:-2], nonspecial_anymore),
          \ a:path[special_index]
          \ ]
    let substr_begin = special_index + 1
  endfor
  let parts += [s:escape(a:path[substr_begin :], nonspecial_anymore)]

  return parts
endfu

fu! s:escape(string, chars) abort
  return escape(fnameescape(a:string), a:chars)
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
      \ [ 'SPECIAL',           '[?*+@!()|{}\[\]\^]'],
      \ [ 'ANy',               '.'                 ],
      \ ]

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
