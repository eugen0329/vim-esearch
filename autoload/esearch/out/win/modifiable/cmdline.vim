let s:String  = vital#esearch#import('Data.String')
let s:Log = esearch#log#import()

let s:multiline_atom_re = g:esearch#util#even_count_of_escapes_re.'\\\%(_\.\|n\)'
let s:multiline_string_re = g:esearch#util#even_count_of_escapes_re.'\\r'

let s:offset_re  = '%(%([esb][\-+]|[\-+])=\d+)' " see :h {offset}
let s:address_re =
      \'%('
      \.  '\.|\$|\%|''.|\\/|\\?|\\&|\d+|/%(\\.|.)*/|\?%(\\.|.)*\?'
      \.')'.s:offset_re.'=' " see {address}
let s:range_re = '('.s:address_re.'%([,;]'.s:address_re.')*)'
" partially taken from vim over
let s:slash_re   = '([\x00-\xff]&[^\\"|[:alnum:][:blank:]])'
let s:pattern_re = '(%(\\.|.){-})'
let s:string_re  = '(\3%(\\.|.){-})'
let s:flags_re   = '%((\3[&cegiInp#lr])*\s*)'
let s:count_re   = '(\s[1-9]\d*)'
" :[range]s[ubstitute]/{pattern}/{string}/[flags] [count]
let s:substitute_command_re = '\v^:*'
      \ . s:range_re . '='
      \ . '(s%[ubstitute]|sno%[magic]|sm%[agic]|ES%[ubstitute])'
      \ . s:slash_re
      \ . '%('
      \ .   s:pattern_re
      \ .   '%('
      \ .     s:string_re
      \ .     '%('
      \ .       s:flags_re
      \ .       s:count_re.'='
      \ .     ')='
      \ .   ')='
      \ . ')=$'

fu! esearch#out#win#modifiable#cmdline#replace(cmdline, cmdtype) abort
  if a:cmdtype !=# ':'	
    return a:cmdline	
  endif	

  let default_pattern = @/	
  let parsed = s:maybe_substitute(a:cmdline, default_pattern)	
  if empty(parsed)
    return a:cmdline
  endif

  if match(parsed.command, 'E\%[Substitute]') >= 0
    call s:warn_cmd_deprecated('esearch: '.parsed.command.' command is deprecated. Use :sbustitute/ and :write commands instead.')
    let parsed.command = 's'
  endif
  if match(empty(parsed.pattern) ? default_pattern : parsed.pattern, s:multiline_atom_re) >= 0
    call s:Log.warn("esearch: Can't match newlines using \\_. or \\n")
    return ''
  endif
  if match(parsed.string, s:multiline_string_re) >= 0
    call s:Log.warn("esearch: Can't add newlines using \\r")
    return ''
  endif

  return parsed.str()
endfu

fu! s:maybe_substitute(cmdline, default_pattern) abort
  let matches = matchlist(a:cmdline, s:substitute_command_re)[1:7]
  if type(matches) == type(0) || empty(matches)
    return {}
  endif

  " :[range]s[ubstitute]/{pattern}/{string}/[flags] [count]
  return {
        \ 'range':   matches[0],
        \ 'command': matches[1],
        \ 'slash':   matches[2],
        \ 'pattern': s:safe_pattern(matches[3], a:default_pattern),
        \ 'string':  matches[4],
        \ 'flags':   matches[5],
        \ 'count':   matches[6],
        \ 'str':     function('<SID>str'),
        \}
endfu

fu! s:safe_pattern(original_pattern, default_pattern) abort
  let pattern = empty(a:original_pattern) ? a:default_pattern : a:original_pattern

  if s:String.starts_with(pattern, g:esearch#out#win#ignore_ui_re)
    return a:original_pattern
  endif

  return g:esearch#out#win#ignore_ui_re . '\%(' . pattern . '\M\)'
endfu

fu! s:str() abort dict
  return    self.range
        \ . self.command
        \ . self.slash
        \ . self.pattern
        \ . self.string
        \ . self.flags
        \ . self.count
endfu

" Used only for ES command deprecation warning. Should be removed later
if g:esearch#has#timers
  fu! s:warn_cmd_deprecated(msg) abort dict
    return timer_start(0, function('<SID>warn_on_next_tick_cb', [a:msg]))
  endfu
  fu! s:warn_on_next_tick_cb(msg, _timer) abort
    return s:Log.warn(a:msg)
  endfu
else
  fu! s:warn_cmd_deprecated(msg) abort dict
    return s:Log.warn(a:msg)
  endfu
endif
