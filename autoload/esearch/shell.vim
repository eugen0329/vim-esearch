let s:Filepath = vital#esearch#import('System.Filepath')
let s:Lexer    = vital#esearch#import('Text.Lexer')
let s:Parser   = vital#esearch#import('Text.Parser')

let s:metachars = '()[]{}?*+@!$^|'

" From src/vim.h
if g:esearch#has#windows
  let g:esearch#shell#path_esc_chars = " \t\n*?[{`%#'\"|!<"
elseif g:esearch#has#vms
  let g:esearch#shell#path_esc_chars = " \t\n*?{`\\%#'\"|!"
else
  let g:esearch#shell#path_esc_chars = " \t\n*?[{`$\\%#'\"|!<"
endif

fu! esearch#shell#split(string) abort
  let splitter = s:Splitter.new(a:string)
  return [splitter.split(), splitter.error]
endfu

let s:rules = [
      \  ['DQ',                '"'                             ],
      \  ['SQ',                "'"                             ],
      \  ['ESCAPED_DQ',        '\\"'                           ],
      \  ['ESCAPED_SQ',        '\\'''                          ],
      \  ['TRAILING_ESCAPE',   '\\$'                           ],
      \  ['WS',                '\s\+'                          ],
      \  ['ESCAPED_ANY',       '\\.'                           ],
      \  ['METACHARS',         '['.escape(s:metachars, ']').']'],
      \  ['REGULAR',           '\%([[:alnum:]/\-_.]\+\|.\)'    ],
      \]

let s:Splitter = { 'error': 0, 'p': 0 }
fu! s:Splitter.new(str) abort dict
  let lexer = s:Lexer.lexer(s:rules).exec(a:str)
  let instance = extend(s:Parser.parser().exec(lexer), deepcopy(self))
  let instance.str = a:str
  return instance
endfu

" Process string using shell rules.
" Does:
"   - dequotation
"   - validation of missed closing quotes and trailing slashes
"   - finding unescaped special locations (for highlight and preserving from fnameescape)
" Returns a list of dicts with fields:
"   .str       - string
"   .metachars - indexes where special chars are located
fu! s:Splitter.split() abort dict
  let paths = []

  while ! self.end()
    if self.next_is(['WS'])
      call self.advance()
    else
      call add(paths, self.consume_path())
    endif
  endwhile

  return paths
endfu

fu! s:Splitter.consume_squote() dict abort
  let parsed = ''
  let begin = self.p
  call self.advance()

  while ! self.end()
    if self.next_is(['REGULAR'])
      let parsed .= self.advance().matched_text
    elseif self.next_is(['SQ'])
      call self.advance()
      return parsed
    elseif self.next_is(['ESCAPED_SQ'])
      call self.advance()
      return parsed.'\'
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  let self.error = 'unterminated single quote at column ' . begin
  return ''
endfu

fu! s:Splitter.consume_dquote() dict abort
  let parsed = ''
  let begin = self.p
  call self.advance()

  while ! self.end()
    if self.next_is(['REGULAR'])
      let parsed .= self.advance().matched_text
    elseif self.next_is(['ESCAPED_DQ', 'ESCAPED_ANY'])
      let parsed .= self.advance().matched_text[1]
    elseif self.next_is(['DQ'])
      let tok = self.advance()
      return parsed
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  let self.error = 'unterminated double quote at column ' . begin
  return ''
endfu

fu! s:Splitter.consume_path() abort dict
  let parsed = ''
  let begin = self.p
  let metachars = []

  while ! self.end()
    if self.next_is(['REGULAR'])
      let parsed .= self.advance().matched_text
    elseif self.next_is(['ESCAPED_SQ', 'ESCAPED_DQ', 'ESCAPED_ANY'])
      let parsed .= self.advance().matched_text[1]
    elseif self.next_is(['DQ'])
      let parsed .= self.consume_dquote()
    elseif self.next_is(['SQ'])
      let parsed .= self.consume_squote()
    elseif self.next_is(['METACHARS'])
      call add(metachars, strchars(parsed))
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

  return s:path(parsed, begin, self.p, metachars)
endfu

fu! s:path(str, begin, end, metachars) abort
  return {'str': a:str, 'begin': a:begin, 'end': a:end, 'metachars': a:metachars}
endfu

fu! esearch#shell#path(str) abort
  return s:path(a:str, 0, 0, [])
endfu

fu! s:Splitter.advance() abort dict
  let token = self.consume()
  let self.p  += strchars(token.matched_text)

  return token
endfu

fu! esearch#shell#escape(path) abort
  return join(esearch#shell#split_by_metachars(a:path), '')
endfu

" Returns a list in format [str1, meta1, ...] to conveniently highlight the
" metachars
fu! esearch#shell#split_by_metachars(path) abort
  if !g:esearch#has#shell_glob | return [shellescape(a:path.str)] | endif
  let str = a:path.str

  let parts = []
  let substr_begin = 0
  for special_index in a:path.metachars
    let parts += [s:fnameescape(str[substr_begin : special_index][:-2]), str[special_index]]
    let substr_begin = special_index + 1
  endfor
  let parts += [s:fnameescape(str[substr_begin :])]

  if parts[0] =~# '^[+>]' || (len(parts) == 1 && parts[0] ==# '-')
    let parts[0] = '\' . parts[0]
  endif

  return parts
endfu

fu! s:fnameescape(string) abort
  return escape(a:string, s:metachars . g:esearch#shell#path_esc_chars)
endfu
