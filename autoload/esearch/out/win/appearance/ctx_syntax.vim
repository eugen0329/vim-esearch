let g:esearch#out#win#appearance#ctx_syntax#map = {
      \ 'c':               'es_ctx_c',
      \ 'cpp':             'es_ctx_c',
      \ 'xs':              'es_ctx_c',
      \ 'cmod':            'es_ctx_c',
      \ 'rpcgen':          'es_ctx_c',
      \ 'haskell':         'es_ctx_haskell',
      \ 'lhaskell':        'es_ctx_haskell',
      \ 'agda':            'es_ctx_haskell',
      \ 'sh':              'es_ctx_sh',
      \ 'bash':            'es_ctx_sh',
      \ 'zsh':             'es_ctx_sh',
      \ 'bats':            'es_ctx_sh',
      \ 'javascript':      'es_ctx_javascript',
      \ 'javascriptreact': 'es_ctx_javascriptreact',
      \ 'typescript':      'es_ctx_typescript',
      \ 'typescriptreact': 'es_ctx_typescriptreact',
      \ 'coffee':          'es_ctx_javascript',
      \ 'litcoffee':       'es_ctx_javascript',
      \ 'php':             'es_ctx_php',
      \ 'phtml':           'es_ctx_php',
      \ 'go':              'es_ctx_go',
      \ 'ruby':            'es_ctx_ruby',
      \ 'racc':            'es_ctx_ruby',
      \ 'xml':             'es_ctx_xml',
      \ 'svg':             'es_ctx_xml',
      \ 'ant':             'es_ctx_xml',
      \ 'papp':            'es_ctx_xml',
      \ 'html':            'es_ctx_html',
      \ 'xhtml':           'es_ctx_html',
      \ 'haml':            'es_ctx_html',
      \ 'htmlcheetah':     'es_ctx_html',
      \ 'wml':             'es_ctx_html',
      \ 'jsp':             'es_ctx_html',
      \ 'template':        'es_ctx_html',
      \ 'htmldjango':      'es_ctx_html',
      \ 'htmlm4':          'es_ctx_html',
      \ 'vue':             'es_ctx_html',
      \ 'java':            'es_ctx_java',
      \ 'python':          'es_ctx_python',
      \ 'kivy':            'es_ctx_python',
      \ 'pyrex':           'es_ctx_python',
      \ 'json':            'es_ctx_json',
      \ 'yaml':            'es_ctx_yaml',
      \ 'liquid':          'es_ctx_yaml',
      \ 'toml':            'es_ctx_toml',
      \ 'dockerfile':      'es_ctx_dockerfile',
      \ 'css':             'es_ctx_css',
      \ 'scss':            'es_ctx_css',
      \ 'sass':            'es_ctx_css',
      \ 'less':            'es_ctx_css',
      \ 'hcl':             'es_ctx_hcl',
      \ 'groovy':          'es_ctx_groovy',
      \ 'vim':             'es_ctx_vim',
      \ 'Jenkinsfile':     'es_ctx_groovy',
      \ 'scala':           'es_ctx_scala',
      \ 'lisp':            'es_ctx_lisp',
      \ 'clojure':         'es_ctx_lisp',
      \ 'rust':            'es_ctx_generic',
      \ 'swift':           'es_ctx_generic',
      \ 'elixir':          'es_ctx_generic',
      \ 'erlang':          'es_ctx_generic',
      \ 'fortran':         'es_ctx_generic',
      \}

fu! esearch#out#win#appearance#ctx_syntax#init(esearch) abort
  let Callback = function('s:highlight_viewport_cb', [a:esearch])
  let a:esearch.ctx_syntax_loaded = 1
  let a:esearch.hl_ctx_syntax = esearch#debounce(Callback, a:esearch.win_contexts_syntax_debounce_wait)
  let a:esearch.context_syntax_regions = {}
  let a:esearch.max_lines_found = 0
  syntax sync minlines=100
  aug esearch_win_hl_ctx_syntax
    au CursorMoved <buffer> call b:esearch.hl_ctx_syntax.apply()
  aug END
endfu

fu! esearch#out#win#appearance#ctx_syntax#uninit(esearch) abort
  aug esearch_win_hl_ctx_syntax
    au! * <buffer>
  aug END
  if has_key(a:esearch, 'hl_ctx_syntax')
    call a:esearch.hl_ctx_syntax.cancel()
  endif
  syntax sync clear
  syntax clear
  let a:esearch.context_syntax_regions = {}
endfu

fu! esearch#out#win#appearance#ctx_syntax#soft_stop(esearch) abort
  aug esearch_win_hl_ctx_syntax
    au! * <buffer>
  aug END
  if has_key(a:esearch, 'hl_ctx_syntax')
    call a:esearch.hl_ctx_syntax.cancel()
  endif

  if a:esearch.win_ui_nvim_syntax
    syn clear
  else
    for name in map(values(a:esearch.context_syntax_regions), 'v:val.name')
      exe 'syn clear ' . name
      exe 'syn clear esearchContext_' . name
    endfor
  endif
  let a:esearch.context_syntax_regions = {}
  syntax sync clear
  syntax sync maxlines=1
endfu

" Can be used to highlight 
fu! esearch#out#win#appearance#ctx_syntax#apply_to_viewport_without_margins(esearch) abort
  if !get(a:esearch, 'ctx_syntax_loaded', 0) | return | endif
  let begin = esearch#util#clip(line('w0'), 3, line('$'))
  let end   = esearch#util#clip(line('w$'), 3, line('$'))
  return s:highlight_viewport(a:esearch, begin, end)
endfu

fu! s:highlight_viewport_cb(esearch) abort
  let begin = esearch#util#clip(line('w0') - a:esearch.win_viewport_off_screen_margin, 3, line('$'))
  let end   = esearch#util#clip(line('w$') + a:esearch.win_viewport_off_screen_margin, 3, line('$'))
  return s:highlight_viewport(a:esearch, begin, end)
endfu

fu! s:highlight_viewport(esearch, begin, end) abort
  if !a:esearch.highlights_enabled || line('$') < 3 || !a:esearch.is_current()
    return
  endif

  let state = esearch#out#win#_state(a:esearch)
  for ctx in b:esearch.contexts[state.ctx_ids_map[a:begin] : state.ctx_ids_map[a:end]]
    if !ctx.syntax_loaded
      call s:define_context_filetype_syntax_region(a:esearch, ctx)
    endif
  endfor
  call s:update_syntax_sync(a:esearch)
endfu

fu! s:update_syntax_sync(esearch) abort
  if !a:esearch.highlights_enabled
        \ || a:esearch['max_lines_found'] < 1
    return
  endif

  "" for some reason it clears other properties which doesn't related to sync
  "" like syn iskeyword etc.
  " syntax sync clear
  exe 'syntax sync minlines='.min([
        \ float2nr(a:esearch.max_lines_found),
        \ a:esearch.win_contexts_syntax_sync_minlines])
endfu

fu! s:define_context_filetype_syntax_region(esearch, ctx) abort
  if empty(a:ctx.filetype)
    let a:ctx.filetype = esearch#ftdetect#fast(a:ctx.filename)
  endif

  if !has_key(g:esearch#out#win#appearance#ctx_syntax#map, a:ctx.filetype)
    let a:ctx.syntax_loaded = -1
    return
  endif
  let syntax_name = g:esearch#out#win#appearance#ctx_syntax#map[a:ctx.filetype]

  if !has_key(a:esearch.context_syntax_regions, syntax_name)
    let region = {
          \ 'cluster': s:include_syntax_cluster(syntax_name),
          \ 'name':    syntax_name,
          \ }
    let a:esearch.context_syntax_regions[syntax_name] = region
    exe printf('syntax region %s start="^ " end="^$" contained contains=esearchLineNr,%s',
          \ region.name,
          \ region.cluster)
  else
    let region = a:esearch.context_syntax_regions[syntax_name]
  endif

  " fnameescape() is used as listed filenames are escaped
  " escape(..., '/...) as the filename pattern is enclosed in //
  " escape(..., ...^$.[\') is used as matching must be literal
  let start = escape(fnameescape(a:ctx.filename), '/^$.[\')
  exe printf('syntax region esearchContext_%s start=/\M^%s$/ end=/^$/ contains=esearchFilename,%s',
        \ region.name, start, region.name)

  let len = a:ctx.end - a:ctx.begin
  if a:esearch.max_lines_found < len
    let a:esearch.max_lines_found = len
  endif
  let a:ctx.syntax_loaded = 1
endfu

fu! s:include_syntax_cluster(ft) abort
  let cluster_name = '@' . toupper(a:ft)

  if exists('b:current_syntax')
    let syntax_save = b:current_syntax
    unlet b:current_syntax
  endif

  exe 'syntax include' cluster_name 'syntax/' . a:ft . '.vim'

  if exists('syntax_save')
    let b:current_syntax = syntax_save
  elseif exists('b:current_syntax')
    unlet b:current_syntax
  endif
  return cluster_name
endfu
