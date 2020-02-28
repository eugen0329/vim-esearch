if !exists('s:saved_global_options')
  let s:saved_global_options = {}
endif

fu! esearch#option#make_local_to_buffer(option_name, value, leak_prevention_events) abort
  augroup ESearchOption
    au! * <buffer>
    execute printf('au BufEnter <buffer> call s:set(%s, %s)',
          \ string(a:option_name), string(a:value))
    execute printf('au BufLeave,BufUnload <buffer> call s:restore(%s)',
          \ string(a:option_name))
  augroup END

  if !empty(a:leak_prevention_events)
    " if :noautocmd is used - option won't be reset to the original value, but
    " backup events may be used to prevent a:value from a leak outside the
    " buffer
    augroup ESearchEnsureGlobalOptionNotLeaked
      au!
      execute s:prevent_leak_event_command(
            \ a:option_name, bufnr(), a:leak_prevention_events)
    augroup END
  endif

  execute 'call s:set('.string(a:option_name).','.string(a:value).')'
endfu

fu! esearch#option#reset() abort
  augroup ESearchOption
    au! * <buffer>
  augroup END
  augroup ESearchEnsureGlobalOptionNotLeaked
    au! *
  augroup END

  for saved in keys(s:saved_global_options)
    call s:restore(saved)
  endfor
endfu

fu! s:ensure_restored(option_name, bufnr, leak_prevention_events) abort
  if bufnr('%') == a:bufnr
    return
  endif
  augroup ESearchEnsureGlobalOptionNotLeaked
    au! *
  augroup END

  call s:restore(a:option_name)
  call s:reload_leak_prevention_event(
        \  a:option_name, a:bufnr, a:leak_prevention_events)
endfu

fu! s:prevent_leak_event_command(option_name, bufnr, leak_prevention_events) abort
  " To not affect the overall performance, s:ensure_restored() will be executed
  " once on a specified event if outside the buffer. Reset (au!) is done within
  " the function instead of ++once, as vim doesn't expose functionality to
  " configure hook for-each-buffer-except a:bufnr. Another alternative would be
  " using CursorMoved, as it's fired ignore :noautocmd, but it's a bit worse in
  " terms of performance within a search window, which is already slightly
  " decreased due to the virtual interface recovery on frequently executed
  " CursorMoved and TextChanged events
  return printf('au %s * ++nested call s:ensure_restored(%s, %d, %s)',
        \ a:leak_prevention_events,
        \ string(a:option_name),
        \ a:bufnr,
        \ string(a:leak_prevention_events),
        \ )
endfu

fu! s:reload_leak_prevention_event(option_name, bufnr, leak_prevention_events) abort
  " Once the leak is prevented, we have to set the event back. The safest event is
  " CursorMoved, configured for the <buffer> only.
  augroup ESearchEnsureGlobalOptionNotLeaked
    au!
    let prevent_leak_autocommand = s:prevent_leak_event_command(
          \ a:option_name, a:bufnr, a:leak_prevention_events)
    execute printf('au CursorMoved,BufEnter <buffer=%d> ++once %s',
          \ a:bufnr, prevent_leak_autocommand)
  augroup END
endfu

fu! s:set(option_name, value) abort
  if !has_key(s:saved_global_options, a:option_name)
    let s:saved_global_options[a:option_name] = eval('&' . a:option_name)
  endif
  execute printf('let &g:%s = %s', a:option_name, string(a:value))
endfu

fu! s:restore(option_name) abort
  execute printf('let &g:%s = s:saved_global_options[%s]',
        \ a:option_name, string(a:option_name))
endfu
