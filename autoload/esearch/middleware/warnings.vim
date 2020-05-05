let s:Message  = esearch#message#import()

" Is used to unobtrusive warn users about deprecations without blocking the
" input or triggering 'more' prompt
fu! esearch#middleware#warnings#apply(esearch) abort
  if empty(g:esearch.pending_deprecations)
    return a:esearch
  endif

  for message in g:esearch.pending_deprecations
    call s:Message.warn('DEPRECATION: ' . message)
    redraw
  endfor

  if len(g:esearch.pending_deprecations) > 1
    call s:Message.warn(printf('DEPRECATION: %s. Run :messages to view all %d',
          \ g:esearch.pending_deprecations[-1],
          \ len(g:esearch.pending_deprecations)))
  endif
  let g:esearch.pending_deprecations = []

  return a:esearch
endfu
