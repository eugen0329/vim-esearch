let s:Vital    = vital#esearch#new()
let s:Message  = s:Vital.import('Vim.Message')

" Builtin confirm() is not working during tests
fu! esearch#ui#confirm#show(message, options) abort
  call s:Message.echo('MoreMsg', a:message)
  call s:Message.echo('MoreMsg', s:wrap_shortcuts(a:options) . ':')

  try
    call inputsave()
    while 1
      let choice = esearch#util#getchar()
      if index(g:esearch#cmdline#cancel_selection_chars, choice) >= 0
        return 0
      endif

      for i in range(1, len(a:options))
        if choice =~# '\c' . a:options[i-1][0]
          redraw | echo ''
          return i
        endif
      endfor
    endwhile
  finally
    call inputrestore()
  endtry
endfu

fu! s:wrap_shortcuts(options) abort
  return join(
        \ [s:wrap_first_letter(a:options[0], '[', ']')] +
        \ map(a:options[1:], 's:wrap_first_letter(v:val, "(", ")")')
        \ )
endfu

fu! s:wrap_first_letter(option, open, close) abort
  return a:open . a:option[0] . a:close . a:option[1 :]
endfu
