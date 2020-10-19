let s:Log  = esearch#log#import()

" Is used to unobtrusive warn users about deprecations without blocking the
" input or triggering 'more' prompt
fu! esearch#middleware#warnings#apply(esearch) abort
  if a:esearch.force_exec || empty(g:esearch.pending_warnings)
    return a:esearch
  endif

  call uniq(g:esearch.pending_warnings)
  for msg in g:esearch.pending_warnings
    call s:Log.info(msg)
    redraw
  endfor

  if len(g:esearch.pending_warnings) > 1
    call s:Log.warn(printf('%s. Run :messages to view all %d',
          \ g:esearch.pending_warnings[-1],
          \ len(g:esearch.pending_warnings)))
  endif
  let g:esearch.pending_warnings = []

  return a:esearch
endfu
