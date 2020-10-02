let s:String  = vital#esearch#import('Data.String')
let s:Log = esearch#log#import()

fu! esearch#out#win#modifiable#cmdline#import() abort
  return s:
endfu

fu! esearch#out#win#modifiable#cmdline#repeat(count1) abort
  try
    let cmd = s:parse(@:, s:recognized_commands).make_safe().str()
  catch /^MakeSafeError/
    return ''
  endtry

  return 'for _ in range('.a:count1.') | silent exe "'.escape(cmd, '"\').'" | endfor'
endfu

fu! esearch#out#win#modifiable#cmdline#replace(cmdline, cmdtype) abort
  if a:cmdtype !=# ':'
    return a:cmdline
  endif

  try
    return  s:parse(a:cmdline, s:recognized_commands).make_safe().str()
  catch /^MakeSafeError/
    return ''
  endtry
endfu

fu! s:parse(cmdline, commands) abort
  for cmd in a:commands
    try
      return cmd.parse(a:cmdline)
    catch /^ParseError/
    endtry
  endfor
endfu

let s:offset_re  = '%(%([esb][\-+]|[\-+])=\d+)' " see :h {offset}
let s:address_re =
      \'%('
      \.  '\.|\$|\%|''.|\\/|\\?|\\&|\d+|/%(\\.|.)*/|\?%(\\.|.)*\?'
      \.')'.s:offset_re.'=' " see {address}
let s:range_re = '('.s:address_re.'%([,;]'.s:address_re.')*)'
" partially taken from vim over
let s:colons_re   = '\s*%(:*\s*)*'
let s:slash_re    = '([\x00-\xff]&[^\\"|[:alnum:][:blank:]])'
let s:pattern_re  = '(%(\\.|.){-})'
let s:count_re    = '([1-9]\d*\s*)'

let s:Base = {'is_safe': 0}
fu! s:Base.str() abort dict
  return join(map(copy(self.signature),
        \ 'type(self[v:val]) == type({}) ? self[v:val].str() : self[v:val]'), '')
endfu

let s:Global = extend(copy(s:Base), {
      \ 'klass':     'Global',
      \ 'signature': ['range', 'global', 'slash1', 'pattern', 'slash2', 'cmd']})

let s:vglobal_re = '\vg%[lobal]!|v%[global]'
let s:global_command_re = '\v^'
      \ . s:colons_re . s:range_re . '=' . s:colons_re
      \ . '(g%[lobal]!=|v%[global])'
      \ . s:slash_re
      \ . '%('
      \ .   s:pattern_re . '='
      \ .   '%('
      \ .     '(\3)(.*)='
      \ .   ')='
      \ . ')=$'

fu! s:Global.parse(cmdline) abort dict
  let matches = s:matchlist(a:cmdline, s:global_command_re, 1, 6)
  return extend(copy(self), {
        \ 'range':   matches[0],
        \ 'global':  matches[1],
        \ 'slash1':  matches[2],
        \ 'pattern': s:safe_glob_pattern(matches[3], matches[1] =~# s:vglobal_re),
        \ 'slash2':  matches[4],
        \ 'cmd':     s:parse(matches[5], s:recognized_commands),
        \})
endfu

fu! s:Global.make_safe() abort dict
  if self.cmd.klass ==# 'Delete'
    let self.cmd.is_safe = 1
    let dry_run = s:Any.parse('call add(g:esearch#out#win#modifiable#delete, line("."))')
    exe extend(copy(self), {'cmd': dry_run}).str()
  else
    let self.cmd = self.cmd.make_safe()
  endif

  return self
endfu

let s:Delete = extend(copy(s:Base), {
      \ 'klass':     'Delete',
      \ 'signature': ['range', 'delete', 'register', 'count']})

let s:register_re = '(\s+\D\s*)'
let s:delete_re = '\v^'
      \ . s:colons_re . s:range_re . '=' . s:colons_re
      \ . '(d%[elete]\s*)'
      \ . '%('
      \ .   s:register_re
      \ .   '%('
      \ .     s:count_re.'='
      \ .   ')='
      \ . ')=$'

fu! s:Delete.parse(cmdline) abort dict
  let matches = s:matchlist(a:cmdline, s:delete_re, 1, 4)
  return extend(copy(self), {
        \ 'range':    matches[0],
        \ 'delete':   matches[1],
        \ 'register': matches[2],
        \ 'count':    matches[3],
        \})
endfu

fu! s:Delete.make_safe() abort dict
  if !self.is_safe
    let range_bounds = s:range_bounds(self.range)
    let g:esearch#out#win#modifiable#delete += range(range_bounds[0], range_bounds[1])
  endif
  return self
endfu

let s:Substitute = extend(copy(s:Base), {
      \ 'klass':     'Substitute',
      \ 'signature': ['range', 'substitute', 'slash', 'pattern', 'string', 'flags', 'count']})

let s:string_re   = '(\3%(\\.|.){-})'
let s:flags_re    = '(\3\s*[&cegiInp#lr]*\s*)'
let s:snomagic_re = '\vsno%[magic]'
" :[range]s[ubstitute]/{pattern}/{string}/[flags] [count]
let s:substitute_command_re = '\v^'
      \ . s:colons_re . s:range_re . '=' . s:colons_re
      \ . '(s%[ubstitute]|sno%[magic]|sm%[agic]|ES%[ubstitute])'
      \ . '%('
      \ .   s:slash_re
      \ .   '%('
      \ .     s:pattern_re
      \ .     '%('
      \ .       s:string_re
      \ .       '%('
      \ .         s:flags_re
      \ .         s:count_re.'='
      \ .       ')='
      \ .     ')='
      \ .   ')='
      \ . ')=$'

fu! s:Substitute.parse(cmdline) abort dict
  let matches = s:matchlist(a:cmdline, s:substitute_command_re, 1, 7)
  return extend(copy(self), {
        \ 'range':      matches[0],
        \ 'substitute': matches[1],
        \ 'slash':      matches[2],
        \ 'pattern':    s:safe_substitute_pattern(matches[3], matches[1] =~# s:snomagic_re),
        \ 'string':     matches[4],
        \ 'flags':      matches[5],
        \ 'count':      matches[6],
        \})
endfu

let s:multiline_atom_re = g:esearch#util#even_count_of_escapes_re.'\\\%(_\.\|n\)'
let s:multiline_string_re = g:esearch#util#even_count_of_escapes_re.'\\r'

fu! s:Substitute.make_safe() abort dict
  if match(self.substitute, 'E\%[Substitute]') >= 0
    call s:log_deferred('esearch: '.self.substitute.' command is deprecated. Use :sbustitute/ and :write commands instead.')
    let self.substitute = 's'
  endif
  if match(empty(self.pattern) ? @/ : self.pattern, s:multiline_atom_re) >= 0
    call s:Log.warn("esearch: Can't match newlines using \\_. or \\n")
    throw 'MakeSafeError'
  endif
  if match(self.string, s:multiline_string_re) >= 0
    call s:Log.warn("esearch: Can't add newlines using \\r")
    throw 'MakeSafeError'
  endif

  return self
endfu

let s:Any = extend(copy(s:Base), {'klass': 'Any', 'signature': ['cmdline']})

fu! s:Any.parse(cmdline) abort dict
  return extend(copy(self), {'cmdline': a:cmdline})
endfu

fu! s:Any.make_safe() abort dict
  return self
endfu

let s:recognized_commands = [s:Delete, s:Substitute, s:Global, s:Any]

fu! s:safe_glob_pattern(original_pattern, invert) abort
  let pattern = empty(a:original_pattern) ? @/ : a:original_pattern
  let prefix = a:invert ? g:esearch#out#win#no_ignore_ui_re : g:esearch#out#win#ignore_ui_re

  if s:String.starts_with(pattern, prefix)
    return a:original_pattern
  endif

  if a:invert
    let postfix = '\m\|'.g:esearch#out#win#separator_re.'\|^[^ ]\|\%1l\)'
  else
    let postfix = '\m\)\%>1l'
  endif
  return prefix . '\%(' . pattern .  postfix
endfu

fu! s:safe_substitute_pattern(original_pattern, nomagic) abort
  let pattern = empty(a:original_pattern) ? @/ : a:original_pattern
  let prefix = a:nomagic ? g:esearch#out#win#nomagic_ignore_ui_re : g:esearch#out#win#ignore_ui_re

  if s:String.starts_with(pattern, prefix)
    return a:original_pattern
  endif

  return prefix . '\%(' . pattern . '\m\)\%>1l'
endfu

fu! s:matchlist(cmdline, re, begin, end) abort
  let matches = matchlist(a:cmdline, a:re)[a:begin : a:end]
  if type(matches) == type(0) || empty(matches)
    throw 'ParseError'
  endif

  return matches
endfu

fu! s:range_bounds(range) abort
  let captured = []
  keepjumps silent exe a:range 'call esearch#util#capture_range(captured)'
  return captured[-1]
endfu

" Used only for ES command deprecation warning. Should be removed later
if g:esearch#has#timers
  fu! s:log_deferred(msg) abort dict
    return timer_start(0, function('<SID>warn_on_next_tick_cb', [a:msg]))
  endfu
  fu! s:warn_on_next_tick_cb(msg, _timer) abort
    return s:Log.warn(a:msg)
  endfu
else
  fu! s:log_deferred(msg) abort dict
    return s:Log.warn(a:msg)
  endfu
endif
