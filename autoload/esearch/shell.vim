let s:List     = vital#esearch#import('Data.List')
let s:Filepath = vital#esearch#import('System.Filepath')
let s:Lexer    = vital#esearch#import('Text.Lexer')
let s:Parser   = vital#esearch#import('Text.Parser')

let s:metachars = '()[]{}?*+@!$^|'
let g:esearch#shell#metachars_re = '['.escape(s:metachars, ']').']'

" Split for posix argv and passthrough for windows
fu! esearch#shell#split(string) abort
  if !g:esearch#has#posix_shell | return [a:string, 0] | endif
  let splitter = s:Splitter.new(a:string)
  return [splitter.split(), splitter.error]
endfu

" If an element of <pathspec> starts with '-', it goes after '--' to prevent
" parsing it as an option. <tree> cannot be passed after '--', so partitioning
" is required.
fu! esearch#shell#join_pathspec(args) abort
  if !g:esearch#has#posix_shell
    " temporarty workaround for windows shell
    if match(a:args, ' [''"\\]\=-') >= 0
      return ' -- ' . a:args
    else
      return  a:args . ' -- '
    endif
  endif

  let [trees_or_pathspecs, pathspecs] = s:List.partition(s:by_not_option, a:args)
  return esearch#shell#join(trees_or_pathspecs)
        \ . (empty(pathspecs) ? '' : ' -- ' . esearch#shell#join(pathspecs))
endfu

fu! s:not_option(p) abort
  return a:p.str[0] !=# '-'
endfu
let s:by_not_option = function('s:not_option')

fu! esearch#shell#join(args) abort
  if !g:esearch#has#posix_shell | return a:args | endif
  return join(map(copy(a:args), 'esearch#shell#escape(v:val)'), ' ')
endfu

fu! esearch#shell#escape(path) abort
  return join(esearch#shell#split_by_metachars(a:path), '')
endfu

" Posix argv is represented as a list for better completion, highlights and
" validation. Windows argv is represented as a string.
fu! esearch#shell#argv(strs) abort
  if g:esearch#has#posix_shell
    return map(copy(a:strs), 's:minimized_arg(v:val)')
  endif

  return join(map(copy(a:strs), 'shellescape(v:val)'))
endfu

" Return a list in format [escaped_str1, meta1, ...] to highlight metachars
fu! esearch#shell#split_by_metachars(path) abort
  if !g:esearch#has#posix_shell | return [shellescape(a:path.str), ''] | endif
  if a:path.raw | return [a:path.str, ''] | endif
  let str = a:path.str
  let parts = []
  let substr_begin = 0
  for i in a:path.metachars
    let parts += [s:fnameescape(str[substr_begin : i][:-2]), str[i]]
    let substr_begin = i + 1
  endfor
  let parts += [s:fnameescape(str[substr_begin :])]

  if parts[0] =~# '^[+>]' || (len(parts) == 1 && parts[0] ==# '-')
    let parts[0] = '\' . parts[0]
  endif

  return parts
endfu

let s:rules = [
      \ ['DQ',            '"'                              ],
      \ ['SQ',            "'"                              ],
      \ ['ESCAPED_DQ',    '\\"'                            ],
      \ ['ESCAPED_SQ',    '\\'''                           ],
      \ ['TRAILING_CHAR', '[`\\]$'                         ],
      \ ['WS',            '\s\+'                           ],
      \ ['ESCAPED_ANY',   '\\.'                            ],
      \ ['EVAL',          '`[^`]\{-}`'                     ],
      \ ['METACHARS',     g:esearch#shell#metachars_re],
      \ ['REGULAR',       '\%([[:alnum:]/\-_.]\+\|.\)'     ],
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
  let args = []

  while ! self.end()
    if self.next_is(['WS'])
      call self.advance()
    elseif self.next_is(['EVAL'])
      call add(args, self.consume_eval())
    else
      call add(args, self.consume_arg())
    endif
  endwhile

  return args
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
  return parsed
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
  return parsed
endfu

fu! s:Splitter.consume_eval() abort dict
  let begin = self.p
  let parsed = self.advance().matched_text
  return s:arg(parsed, begin, self.p, [], 1)
endfu

fu! s:Splitter.consume_arg() abort dict
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
    elseif self.next_is(['TRAILING_CHAR'])
      let self.error = 'trailing ' . string(self.advance().matched_text)
    else
      let parsed .= self.advance().matched_text
    endif
  endwhile

  return s:arg(parsed, begin, self.p, metachars, 0)
endfu

" Vital relpath converts home to ~. It cause problems with vim's builtin
" isdirectory(), so fnamemodify is used.
fu! s:minimized_arg(path) abort
  if s:Filepath.is_relative(a:path)
    return s:arg(a:path, 0, 0, [], 0)
  endif

  return s:arg(fnamemodify(a:path, ':.'), 0, 0, [], 0)
endfu

fu! s:arg(str, begin, end, metachars, raw) abort
  return {'str': a:str, 'begin': a:begin, 'end': a:end, 'metachars': a:metachars, 'raw': a:raw}
endfu

fu! s:Splitter.advance() abort dict
  let token = self.consume()
  let self.p  += strchars(token.matched_text)

  return token
endfu

" From src/vim.h
if g:esearch#has#windows
  let s:path_esc_chars = " \t\n*?[{`%#'\"|!<"
elseif g:esearch#has#vms
  let s:path_esc_chars = " \t\n*?{`\\%#'\"|!"
else
  let s:path_esc_chars = " \t\n*?[{`$\\%#'\"|!<"
endif

fu! s:fnameescape(string) abort
  return escape(a:string, s:metachars . s:path_esc_chars)
endfu
