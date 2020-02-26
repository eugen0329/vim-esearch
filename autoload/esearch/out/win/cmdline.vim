let s:Vital   = vital#esearch#new()
let s:String  = s:Vital.import('Data.String')
let s:Message  = s:Vital.import('Vim.Message')
let s:linenr_format = ' %3d '

fu! esearch#out#win#cmdline#handle(event) abort
  let substitute = s:parse_substitute(a:event.cmdline)
  if !empty(substitute)
    return s:safely_replay_substitute(a:event, substitute)
  endif

  call esearch#out#win#unsupported#handle(a:event)
endfu

fu! s:safely_replay_substitute(event, command) abort
  if s:is_dry_run(a:command.flags)
    return
  endif
  if s:is_size_changed(a:event)
    call s:Message.echo('ErrorMsg', 'Multiline command is not allowed')
    return esearch#out#win#unsupported#handle(a:event)
  endif

  let original_pattern = a:command.get_pattern()
  let safe_pattern = s:safe_pattern(original_pattern)
  if original_pattern ==# safe_pattern
    return
  endif
  let a:command.pattern = safe_pattern

  try
    if stridx(a:command.flags, 'c') >= 0
      call s:replay_confirmable(a:event, a:command, original_pattern)
    else
      call s:replay(a:event, a:command, original_pattern)
    endif
  finally
    let @/ = a:command.pattern
    call b:esearch.undotree.synchronize()
  endtry
endfu

fu! s:replay(event, command, original_pattern) abort
  silent undo
  call b:esearch.undotree.mark_block_as_corrupted()
  let found = s:execute(a:command.to_string(), a:original_pattern)
endfu

fu! s:replay_confirmable(event, command, original_pattern) abort
  let a:command.flags = substitute(a:command.flags, 'c', '', '')
  call s:undo_corrupted_blocks_until(a:event.changenr1)
  noau exe 'silent undo ' . a:event.changenr1
  call s:execute(a:command.to_string(), a:original_pattern)
endfu

fu! s:execute(command_string, original_pattern) abort
  redraw " clear previous substitute output
  try
    " NOTE capture use 'silent' under the hood which swaps backwards ranges, so
    " it's not equivalent to calling builtin execute() instead
    echo trim(s:Message.capture(a:command_string), "\n")
  catch /E486:/
    call s:Message.echo('ErrorMsg', 'E486: Pattern not found: ' . a:original_pattern)
  endtry
endfu

fu! s:undo_corrupted_blocks_until(block_number) abort
  let visited = 0

  while visited < &undolevels
    let block_number = changenr()
    if block_number <= block_number
          \  || has_key(b:esearch.undotree.nodes, block_number)
      break
    endif

    call b:esearch.undotree.mark_block_as_corrupted()
    noautocmd silent undo
    let visited += 1
  endwhile
endfu

fu! s:safe_pattern(pattern) abort
  let pattern = a:pattern

  if !s:String.starts_with(a:pattern, g:esearch#out#win#result_text_regex_prefix)
    let pattern = g:esearch#out#win#result_text_regex_prefix . a:pattern
  endif

  return pattern
endfu

fu! s:parse_substitute(word)
  " partially taken from vim over
  let very_magic  = '\v'
  let range       = '(.{-})'
  let command     = '(s%[ubstitute])'
  let first_slash = '([\x00-\xff]&[^\\"|[:alnum:][:blank:]])'
  let pattern     = '(%(\\.|.){-})'
  let string      = '(\3%(\\.|.){-})'
  let flags       = '(\3[&cegiInp#lr]*\s*)'
  let cnt         = '%((\s[1-9]\d*))?'

  let parse_pattern
        \   = very_magic
        \   . '^:*'
        \   . range
        \   . command
        \   . first_slash
        \   . pattern
        \   . '%('
        \   . string
        \   . '%('
        \   . flags
        \   . cnt
        \   . ')?)?'
        \   . '$'

  let parts = matchlist(a:word, parse_pattern)[1:7]
  if type(parts) == type(0) || empty(parts)
    return {}
  endif

  return {
        \ 'range':            parts[0],
        \ 'command':          parts[1],
        \ 'slash':            parts[2],
        \ 'pattern':          parts[3],
        \ 'string':           parts[4],
        \ 'flags':          parts[5],
        \ 'count':            parts[6],
        \ 'previous_pattern': @/,
        \ 'to_string':        function('<SID>to_string'),
        \ 'get_pattern':      function('<SID>get_pattern'),
        \ }
endfu

fu! s:to_string() abort dict
  return self.range
        \ . self.command
        \ . self.slash
        \ . self.pattern
        \ . self.string
        \ . self.flags
        \ . self.count
endfu

fu! s:get_pattern() abort dict
  if empty(self.pattern)
    return self.previous_pattern
  endif
  return self.pattern
endfu

fu! s:is_dry_run(flags) abort
  " [n] Report the number of matches, do not actually substitute.
  return stridx(a:flags, 'n') >= 0
endfu

fu! s:is_size_changed(event) abort
  return a:event.original_size != line('$')
endfu
