if !exists('s:saved_global_options')
  let s:saved_global_options = {}
endif

" Rationale:
"   There are global options that are required to be configured for a buffer
"   only (like 'updatetime' or 'backspace'). Usually, imitation of buffer-local
"   options for global onces is done using restoring original values on BufLeave
"   and setting them back on BufEnter autocommands.  This autocommands may be
"   ignored using :noautocmd or 'eventignore'. The plugin doesn't use them to
"   navigate buffers, but other plugins may, so to prevent annoying option
"   values leak the following approach is used:
"   - set/restore are called on BufEnter and BufLeave,BufUnload events
"   accordingly for the target buffer only (using <buffer>).
"   - a separate global backup event is set to ensure the options is restored to
"   the original value. This event is fired once outside the buffer and then
"   removed using :au!.
"   - after ensuring the option is restored (happens outside the target buffer),
"   another event is set to enable the backup event with doublechecks back when
"   the user returns to the target buffer (BufEnter and CursorMoved are used).
"
"   Removing and restoring the backup event is required to not leave garbage
"   events when the search buffer is deleted or the search is not relevant
"   anymore. Another and more reliable approach would be to use CursorMoved
"   (that cannot be skipped with :noautocmd), but it's not the best way in terms
"   of performance within the window, which already listens and do enough of
"   work on CursorMoved event.
"
"   So such method is implemented to mitigate the drawback of vim builtins without
"   affecting the UX (by making cursor movements sluggish within the window) and
"   to not leave garbage evens after the search.

fu! esearch#option#make_local_to_buffer(option_name, value, prevent_leaks_on_events) abort
  augroup ESearchOption
    au! * <buffer>
    execute printf('au BufEnter <buffer> call s:set(%s, %s)',
          \ string(a:option_name), string(a:value))
    execute printf('au BufLeave,BufUnload <buffer> call s:restore(%s)',
          \ string(a:option_name))
  augroup END

  if !empty(a:prevent_leaks_on_events)
    call s:set_events_to_ensure_option_restored(
          \ a:option_name, bufnr('%'), a:prevent_leaks_on_events)
  endif

  execute 'call s:set('.string(a:option_name).','.string(a:value).')'
endfu

fu! esearch#option#reset() abort
  augroup ESearchOption
    au! * <buffer>
  augroup END
  augroup ESearchEnsureGlobalOptionNotLeaked
    au!
  augroup END

  for saved in keys(s:saved_global_options)
    call s:restore(saved)
  endfor
endfu

fu! s:ensure_restored(option_name, bufnr, prevent_leaks_on_events) abort
  if bufnr('%') == a:bufnr
    return
  endif

  call s:restore(a:option_name)

  augroup ESearchEnsureGlobalOptionNotLeaked
    au!
    if bufexists(a:bufnr)
      " Once the leak is prevented, we have to set the event back. Semantically,
      " the right event is BufEnter, configured for the target <buffer>, but the safest
      " way is to backup it with CursorMoved, as it's cannot be skipped with :noautocmd
      execute printf('au BufEnter,CursorMoved <buffer=%d> ++once call s:set_events_to_ensure_option_restored(%s, %d, %s)',
            \ a:bufnr, string(a:option_name), string(a:bufnr), string(a:prevent_leaks_on_events))
    endif
  augroup END
endfu

fu! s:set_events_to_ensure_option_restored(option_name, bufnr, prevent_leaks_on_events) abort
  augroup ESearchEnsureGlobalOptionNotLeaked
    au!
    execute printf('au %s * call s:ensure_restored(%s, %d, %s)',
        \ a:prevent_leaks_on_events,
        \ string(a:option_name),
        \ a:bufnr,
        \ string(a:prevent_leaks_on_events),
        \ )
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
