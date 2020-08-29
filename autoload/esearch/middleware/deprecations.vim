" Translate deprecated configurations and set deprecation warnings
fu! esearch#middleware#deprecations#apply(esearch) abort
  if get(g:esearch, 'loaded_deprecations', 0)
    return a:esearch
  endif

  if exists('g:esearch#out#win#context_syntax_highlight')
    let g:esearch.win_contexts_syntax = g:esearch#out#win#context_syntax_highlight
    let g:esearch.pending_deprecations += ['g:esearch#out#win#context_syntax_highlight. Please, rename to g:esearch.win_contexts_syntax']
  endif

  if exists('g:esearch#out#win#buflisted')
    au User esearch#win_config let &buflisted = g:esearch#out#win#buflisted
    let g:esearch.pending_deprecations += ['g:esearch#out#win#buflisted, see :help esearch_win_config for details']
  endif

  if exists('g:esearch#out#win#open')
    let g:esearch.pending_deprecations += ['g:esearch#out#win#open, see :help g:esearch.win_new for details']
  endif

  if has_key(g:esearch, 'nerdtree_plugin')
    let g:esearch.filemanager_integration = g:esearch.nerdtree_plugin
    let g:esearch.pending_deprecations += ['g:esearch.nerdtree_plugin. Please, use g:esearch.filemanager_integration instead']
  endif

  if has_key(g:esearch, 'use')
    let g:esearch.prefill = type(g:esearch.use) == type('') ? [g:esearch.use] : g:esearch.use
    let g:esearch.pending_deprecations += ['g:esearch.use. Please, use g:esearch.prefill list instead']
  endif

  if index(g:esearch.prefill, 'visual') >= 0
    let g:esearch.pending_deprecations += ["'prefill': ['visual', ...], use <Plug>(esearch-prefill) operator mapping instead"]
    call remove(g:esearch.prefill, index(g:esearch.prefill, 'visual'))
  endif
  if index(g:esearch.prefill, 'word_under_cursor') >= 0
    let g:esearch.pending_deprecations += ["'prefill': ['word_under_cursor', ...], use 'cword' instead"]
    let g:esearch.prefill[index(g:esearch.prefill, 'word_under_cursor')] = 'cword'
  endif
  if index(g:esearch.prefill, 'system_clipboard') >= 0
    let g:esearch.pending_deprecations += ["'prefill': ['system_clipboard', ...], use 'clipboard' instead"]
    let g:esearch.prefill[index(g:esearch.prefill, 'system_clipboard')] = 'clipboard'
  endif
  if index(g:esearch.prefill, 'system_selection_clipboard') >= 0
    let g:esearch.pending_deprecations += ["'prefill': ['system_selection_clipboard', ...], use 'clipboard' instead"]
    let g:esearch.prefill[index(g:esearch.prefill, 'system_selection_clipboard')] = 'clipboard'
  endif

  if has_key(g:esearch, 'word')
    let g:esearch.textobj = g:esearch.word
    let g:esearch.pending_deprecations += ['g:esearch.word, see :help g:esearch.textobj for details']
  endif

  if hlexists('esearchLnum')
    let g:esearch.pending_deprecations += ['highlight esearchLnum. Please, rename to esearchLineNr']
  endif

  if hlexists('esearchFName')
    let g:esearch.pending_deprecations += ['highlight esearchFName. Please, rename to esearchFilename']
  endif

  let g:esearch.loaded_deprecations = 1
  return a:esearch
endfu
