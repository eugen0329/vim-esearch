" Translate deprecated configurations and set deprecation warnings
fu! esearch#middleware#deprecations#apply(esearch) abort
  if get(g:esearch, 'loaded_deprecations', 0)
    return a:esearch
  endif

  if exists('g:esearch#out#win#context_syntax_highlight')
    let g:esearch.win_contexts_syntax = g:esearch#out#win#context_syntax_highlight
    call esearch#util#deprecate('g:esearch#out#win#context_syntax_highlight. Please, rename to g:esearch.win_contexts_syntax')
  endif

  if exists('g:esearch#out#win#buflisted')
    call esearch#util#deprecate('g:esearch#out#win#buflisted, see :help esearch_win_config for details')
    au User esearch_win_config let &buflisted = g:esearch#out#win#buflisted
  endif

  if exists('g:esearch#out#win#open')
    call esearch#util#deprecate('g:esearch#out#win#open, see :help g:esearch.win_new for details')
  endif

  if has_key(g:esearch, 'nerdtree_plugin')
    call esearch#util#deprecate('g:esearch.nerdtree_plugin. Please, use g:esearch.filemanager_integration instead')
    let g:esearch.filemanager_integration = g:esearch.nerdtree_plugin
    let a:esearch.filemanager_integration = g:esearch.nerdtree_plugin
  endif

  if has_key(g:esearch, 'use')
    call esearch#util#deprecate('g:esearch.use. Please, use g:esearch.prefill list instead')
    let g:esearch.prefill = type(g:esearch.use) == type('') ? [g:esearch.use] : g:esearch.use
    let a:esearch.prefill = type(g:esearch.use) == type('') ? [g:esearch.use] : g:esearch.use
  endif

  if index(g:esearch.prefill, 'visual') >= 0
    call esearch#util#deprecate("'prefill': ['visual', ...], use <plug>(esearch-prefill) operator mapping instead")
    call remove(g:esearch.prefill, index(g:esearch.prefill, 'visual'))
    call remove(a:esearch.prefill, index(g:esearch.prefill, 'visual'))
  endif
  if index(g:esearch.prefill, 'word_under_cursor') >= 0
    call esearch#util#deprecate("'prefill': ['word_under_cursor', ...], use 'cword' instead")
    let g:esearch.prefill[index(g:esearch.prefill, 'word_under_cursor')] = 'cword'
    let a:esearch.prefill[index(g:esearch.prefill, 'word_under_cursor')] = 'cword'
  endif
  if index(g:esearch.prefill, 'system_clipboard') >= 0
    call esearch#util#deprecate("'prefill': ['system_clipboard', ...], use 'clipboard' instead")
    let g:esearch.prefill[index(g:esearch.prefill, 'system_clipboard')] = 'clipboard'
    let a:esearch.prefill[index(g:esearch.prefill, 'system_clipboard')] = 'clipboard'
  endif
  if index(g:esearch.prefill, 'system_selection_clipboard') >= 0
    call esearch#util#deprecate("'prefill': ['system_selection_clipboard', ...], use 'clipboard' instead")
    let g:esearch.prefill[index(g:esearch.prefill, 'system_selection_clipboard')] = 'clipboard'
    let a:esearch.prefill[index(g:esearch.prefill, 'system_selection_clipboard')] = 'clipboard'
  endif

  if has_key(g:esearch, 'word')
    call esearch#util#deprecate('g:esearch.word, see :help g:esearch.textobj for details')
    let g:esearch.textobj = g:esearch.word
    let a:esearch.textobj = g:esearch.word
  endif

  if hlexists('esearchLnum')
    call esearch#util#deprecate('highlight esearchLnum. Please, rename to esearchLineNr')
  endif
  if hlexists('esearchFName')
    call esearch#util#deprecate('highlight esearchFName. Please, rename to esearchFilename')
  endif

  let g:esearch.loaded_deprecations = 1
  return a:esearch
endfu
