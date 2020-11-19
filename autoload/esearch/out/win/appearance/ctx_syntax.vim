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

fu! esearch#out#win#appearance#ctx_syntax#init(es) abort
  let a:es.context_syntax_regions = {}
  if !a:es.win_contexts_syntax | retu | en

  let l:Callback = function('s:hl_viewport_cb', [a:es])
  let a:es.loaded_ctx_syntaxes = 1
  let a:es.hl_ctx_syntax = esearch#async#debounce(Callback, a:es.win_contexts_syntax_debounce_wait)
  let a:es.max_lines_found = 0
  syn sync minlines=100
  aug esearch_win_hl_ctx_syntax
    au CursorMoved <buffer> cal b:esearch.hl_ctx_syntax.apply()
  aug END
endfu

fu! esearch#out#win#appearance#ctx_syntax#uninit(es) abort
  aug esearch_win_hl_ctx_syntax
    au! * <buffer>
  aug END
  if has_key(a:es, 'hl_ctx_syntax')
    cal a:es.hl_ctx_syntax.cancel()
  en
  syn sync clear
  syn clear
  let a:es.context_syntax_regions = {}
endfu

fu! esearch#out#win#appearance#ctx_syntax#soft_stop(es) abort
  aug esearch_win_hl_ctx_syntax
    au! * <buffer>
  aug END
  if has_key(a:es, 'hl_ctx_syntax')
    cal a:es.hl_ctx_syntax.cancel()
  en

  if a:es.win_ui_nvim_syntax
    syn clear
  else
    for name in map(values(a:es.context_syntax_regions), 'v:val.name')
      exe 'syn clear ' . name
      exe 'syn clear esearchctx_' . name
    endfor
  en
  let a:es.context_syntax_regions = {}
  syn sync clear
  syn sync maxlines=1
endfu

" Can be used to highlight 
fu! esearch#out#win#appearance#ctx_syntax#hl_viewport(es) abort
  if !get(a:es, 'loaded_ctx_syntaxes') | retu | en
  let l1 = esearch#util#clip(line('w0'), 3, line('$'))
  let l2 = esearch#util#clip(line('w$'), 3, line('$'))
  retu s:hl(a:es, l1, l2)
endfu

fu! s:hl_viewport_cb(es) abort
  let l1 = esearch#util#clip(line('w0') - a:es.win_viewport_off_screen_margin, 3, line('$'))
  let l2 = esearch#util#clip(line('w$') + a:es.win_viewport_off_screen_margin, 3, line('$'))
  retu s:hl(a:es, l1, l2)
endfu

fu! s:hl(es, l1, l2) abort
  if !a:es.slow_hl_enabled || line('$') < 3 || !a:es.is_current() | retu | en
  let s = a:es.state
  for c in b:esearch.contexts[s[a:l1]:s[a:l2]]
    if !c.loaded_syntax | cal s:def_ctx_region(a:es,c) | en
  endfo
  cal s:upd_sync(a:es)
endfu

fu! s:upd_sync(es) abort
  if !a:es.slow_hl_enabled || a:es.max_lines_found < 1 | retu | en
  exe 'syn sync minlines='.min([float2nr(a:es.max_lines_found),a:es.win_contexts_syntax_sync_minlines])
endfu

fu! s:def_ctx_region(es, ctx) abort
  if empty(a:ctx.filetype)
    let a:ctx.filetype = esearch#ftdetect#fast(a:ctx.filename)
  en

  if !has_key(g:esearch#out#win#appearance#ctx_syntax#map, a:ctx.filetype)
    let a:ctx.loaded_syntax = -1
    retu
  en
  let syn = g:esearch#out#win#appearance#ctx_syntax#map[a:ctx.filetype]

  if !has_key(a:es.context_syntax_regions, syn)
    let r = {'cluster': s:include(syn), 'name': syn}
    let a:es.context_syntax_regions[syn] = r
    exe printf('syn region %s start="^ " end="^$" contained contains=esearchLineNr,%s', r.name, r.cluster)
  else
    let r = a:es.context_syntax_regions[syn]
  en

  " fnameescape() is used as listed filenames are escaped
  " escape(..., '/...) as the filename pattern is enclosed in //
  " escape(..., ...^$.[\') is used as matching must be literal
  let start = escape(fnameescape(a:ctx.filename), '/^$.[\')
  exe printf('syn region esearchctx_%s start=/\M^%s$/ end=/^$/ contains=esearchFilename,%s', r.name, start, r.name)

  let len = a:ctx.end - a:ctx.begin
  if a:es.max_lines_found < len | let a:es.max_lines_found = len | en
  let a:ctx.loaded_syntax = 1
endfu

fu! s:include(ft) abort
  if exists('b:current_syntax')
    let syntax_save = b:current_syntax
    unl b:current_syntax
  en
  let clus = '@'.toupper(a:ft)
  exe 'syn include' clus 'syntax/'.a:ft.'.vim'
  if exists('syntax_save')
    let b:current_syntax = syntax_save
  elsei exists('b:current_syntax')
    unl b:current_syntax
  en
  retu clus
endfu
