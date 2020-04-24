let s:String  = vital#esearch#import('Data.String')
let s:List    = vital#esearch#import('Data.List')
let s:Message = esearch#message#import()
let g:esearch#out#win#linenr_format = ' %3d '

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#modifiable#cmdline#handle(event) abort
  let substitute = s:parse_substitute(a:event.cmdline)
  if !empty(substitute)
    return s:safely_replay_substitute(a:event, substitute)
  endif

  call esearch#out#win#modifiable#unsupported#handle(a:event)
endfu

fu! s:safely_replay_substitute(event, command) abort
  if s:is_dry_run(a:command.flags)
    return
  endif
  if s:is_size_changed(a:event)
    call s:Message.echo('ErrorMsg', 'Multiline :substitute is not allowed')
    return esearch#out#win#modifiable#unsupported#handle(a:event)
  endif

  let original_pattern = a:command.get_pattern()
  let safe_pattern = s:safe_pattern(original_pattern)
  if original_pattern ==# safe_pattern
    return
  endif
  let a:command.pattern = safe_pattern
  " Overwrite global search register like builtin :s does.
  " Is executed earlier to prevent blinks
  let @/ = a:command.pattern

  try
    " clear previous command output as soon as apossible as we expect the correct
    " statistics output from :substitute, replayed with the safe pattern.
    echo ''

    if stridx(a:command.flags, 'c') >= 0
      call s:replay_confirmable(a:event, a:command, original_pattern)
    else
      call s:replay(a:event, a:command, original_pattern)
    endif
  finally
    call b:esearch.undotree.synchronize()
  endtry
endfu

fu! s:replay(event, command, original_pattern) abort
  noau keepjumps silent undo
  call b:esearch.undotree.mark_block_as_corrupted()
  call s:execute(a:command.to_str(), a:original_pattern)
endfu

fu! s:replay_confirmable(event, command, original_pattern) abort
  let command_with_confirmation = a:command
  let command = copy(a:command)
  let command.flags = substitute(command.flags, 'c', '', '')
  let [confirmed_lines, remaining_range]
        \ = s:lookup_confirmations_from_undo(a:event.changenr1, a:event.changenr2)
  execute 'noau keepjumps silent undo ' . a:event.changenr1

  let ask_again_on_lines = []
  let state = b:esearch.undotree.head.state
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, state)
  for [modified_text, line] in confirmed_lines
    let context = contexts.by_line(line)
    if context.begin == line || (context.end == line && context.end != line('$'))
      " don't replay changes on top of contexts boundaries (as they contain only
      " the virtual ui)
    else
      let linenr = printf(g:esearch#out#win#linenr_format, state.line_numbers_map[line])

      if s:String.starts_with(modified_text, linenr)
        call setline(line, modified_text) " LineNr isn't corrupted, can be safely replayed
      elseif stridx(command.flags, 'g') < 0
        " if it was the only match in the line and it corrupts the virtual ui
        " - don't replay
      else
        call add(ask_again_on_lines, line)
      endif
    endif
  endfor

  if !empty(remaining_range)
    call s:execute_silently(command.to_str({'range': join(remaining_range, ',')}))
  endif

  for line in ask_again_on_lines
    call s:execute_silently(command_with_confirmation.to_str({'range': line}))
  endfor
endfu

fu! s:execute_silently(command_string) abort
  try
    silent execute a:command_string
  catch /E486:/
    " suppress errors on missing
  endtry
endfu

fu! s:execute(command_string, original_pattern) abort
  redraw " clear previous substitute output
  try
    " NOTE capture use 'silent' under the hood which swaps backwards ranges, so
    " it's not equivalent to calling builtin execute() instead.
    " Swapping feature of silent isn't a hack and documented in :h E493
    echo trim(s:Message.capture(a:command_string), "\n")
  catch /E486:/
    call s:Message.echo('ErrorMsg', 'E486: Pattern not found: ' . a:original_pattern)
  endtry
endfu

" According to :help, undo block is formed on each change no matter the size.
" When [c]onfirmation flag is used, :substitute produce an undo block on each
" confirmed line, so all the confirmed lines can be pretty reliably (to a
" certain extent) fetched from undo history.
fu! s:lookup_confirmations_from_undo(from_block, until_block) abort
  execute 'noau keepjumps silent undo ' . a:from_block

  let visited_blocks = 0
  let remaining_range = []
  let confirmed_lines = []
  while visited_blocks < &undolevels
    if changenr() >= a:until_block
      break
    endif
    noautocmd silent redo

    let [line1, line2] = [line("'["), line("']")]
    " if 'a' is pressed - substitute is executed until the end of a given range,
    " otherwise - changes are recorded line by line
    if line1 < line2
      call assert_true(empty(remaining_range))
      " we should handle line1 more thoroughly as if 'a' is pressed
      " within line1 after at least one 'n', replacing all the remaining_range from
      " line1 may cause overriding of 'n' presses
      let remaining_range = [line1 + 1, line2]
      call add(confirmed_lines, [getline(line1), line1])
    else
      call add(confirmed_lines, [getline(line1), line1])
    endif

    call b:esearch.undotree.mark_block_as_corrupted()
    let visited_blocks += 1
  endwhile

  return [confirmed_lines, remaining_range]
endfu

fu! s:safe_pattern(pattern) abort
  let pattern = a:pattern

  if !s:String.starts_with(a:pattern, g:esearch#out#win#result_text_regex_prefix)
    let pattern = g:esearch#out#win#result_text_regex_prefix . a:pattern
  endif

  return pattern
endfu

fu! s:parse_substitute(word) abort
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
        \ 'flags':            parts[5],
        \ 'count':            parts[6],
        \ 'previous_pattern': @/,
        \ 'to_str':           function('<SID>to_str'),
        \ 'get_pattern':      function('<SID>get_pattern'),
        \ }
endfu

fu! s:to_str(...) abort dict
  let parts = extend(copy(self), get(a:000, 0, {}))
  return parts.range
        \ . parts.command
        \ . parts.slash
        \ . parts.pattern
        \ . parts.string
        \ . parts.flags
        \ . parts.count
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
