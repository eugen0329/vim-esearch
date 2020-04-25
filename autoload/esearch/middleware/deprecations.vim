" Translate deprecated configurations and set deprecation warnings
fu! esearch#middleware#deprecations#apply(esearch) abort
  if g:esearch.deprecations_loaded
    return a:esearch
  endif

  if exists('g:esearch#out#win#context_syntax_highlight')
    let a:esearch.win_contexts_syntax = g:esearch#out#win#context_syntax_highlight
    let g:esearch.pending_deprecations += ['g:esearch#out#win#context_syntax_highlight. Please, rename to g:esearch.win_contexts_syntax']
  endif

  if exists('g:esearch#out#win#buflisted')
    call extend(g:esearch.win_let, {'&l:buflisted': g:esearch#out#win#buflisted})
    let g:esearch.pending_deprecations += ['g:esearch#out#win#buflisted, see :help g:esearch.win_let for details']
  endif

  if exists('g:esearch#out#win#open')
    let g:esearch.pending_deprecations += ['g:esearch#out#win#open, see :help g:esearch.win_new for details']
  endif

  if has_key(a:esearch, 'word')
    let a:esearch.textobj = a:esearch.word
    let g:esearch.pending_deprecations += ['g:esearch.word, see :help g:esearch.textobj for details']
  endif

  let g:esearch.deprecations_loaded = 1
  return a:esearch
endfu
