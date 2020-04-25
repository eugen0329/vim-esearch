fu! esearch#config#eager() abort
  if !exists('g:esearch')
    let g:esearch = {}
  endif

  if !get(g:esearch, 'lazy_loaded', 0)
    call esearch#config#init(g:esearch)
    call s:init_lua()
    let g:esearch.lazy_loaded = 1
    call esearch#util#doautocmd('User eseach_config_eager_post')
  endif
endfu

fu! esearch#config#init(esearch) abort
  let g:esearch = a:esearch

  if !has_key(g:esearch, 'backend')
    let g:esearch.backend = esearch#config#default_backend()
  endif

  if !has_key(g:esearch, 'adapter')
    let g:esearch.adapter = esearch#config#default_adapter()
  endif

  let g:esearch = extend(g:esearch, {
        \ 'last_id':                               0,
        \ 'out':                                   'win',
        \ 'regex':                                 'literal',
        \ 'textobj':                               'none',
        \ 'adapters':                              {},
        \ 'remember':                              ['case', 'textobj', 'regex', 'before', 'filetypes', 'paths', 'after', 'context', 'adapters', 'current_adapter'],
        \ 'paths':                                 [],
        \ 'filetypes':                             '',
        \ 'after':                                 0,
        \ 'before':                                0,
        \ 'context':                               0,
        \ 'early_finish_wait':                     50,
        \ 'default_mappings':                      1,
        \ 'nerdtree_plugin':                       1,
        \ 'root_markers':                          ['.git', '.hg', '.svn', '.bzr', '_darcs'],
        \ 'slice':                                 function('esearch#util#slice'),
        \ 'errors':                                [],
        \ 'prefill':                               ['visual', 'current', 'hlsearch', 'last'],
        \ 'parse_strategy':                        g:esearch#has#lua ? 'lua' : 'viml',
        \ 'win_update_throttle_wait':              g:esearch#has#throttle && g:esearch.backend !=# 'vimproc' ? 100 : 0,
        \ 'win_render_strategy':                   g:esearch#has#lua ? 'lua' : 'viml',
        \ 'win_viewport_off_screen_margins':       &lines > 100 ? &lines : 100,
        \ 'win_matches_highlight_debounce_wait':   100,
        \ 'win_matches_highlight_strategy':        g:esearch#has#nvim_lua_syntax ? 'viewport' : 'matchadd',
        \ 'win_contexts_syntax':                   1,
        \ 'win_contexts_syntax_debounce_wait':     100,
        \ 'win_contexts_syntax_sync_minlines':     500,
        \ 'win_context_syntax_clear_on_line_len':  800,
        \ 'win_contexts_syntax_clear_on_line_len': 30000,
        \ 'win_context_len_annotations':           g:esearch#has#virtual_text,
        \ 'win_cursor_linenr_highlight':           g:esearch#has#virtual_cursor_linenr_highlight,
        \ 'win_let':                               {'&l:buflisted': 0},
        \ 'win_new':                               function('esearch#out#win#goto_or_open'),
        \ 'deprecations_loaded':                   0,
        \ 'pending_deprecations':                  [],
        \}, 'keep')
  let g:esearch = extend(g:esearch, {
        \ 'win_ui_nvim_syntax':                       g:esearch.win_render_strategy ==# 'lua' && g:esearch#has#nvim_lua_syntax,
        \ 'win_contexts_syntax_clear_on_files_count': g:esearch.win_matches_highlight_strategy ==# 'viewport' ? 800 : 200,
        \}, 'keep')

  if !has_key(g:esearch, 'middleware')
    let g:esearch.middleware = [
          \ function('esearch#middleware#deprecations#apply'),
          \ function('esearch#middleware#id#apply'),
          \ function('esearch#middleware#adapter#apply'),
          \ function('esearch#middleware#cwd#apply'),
          \ function('esearch#middleware#paths#apply'),
          \ function('esearch#middleware#nerdtree#apply'),
          \ function('esearch#middleware#prewarm#apply'),
          \ function('esearch#middleware#pattern#apply'),
          \ function('esearch#middleware#remember#apply'),
          \ function('esearch#middleware#exec#apply'),
          \ function('esearch#middleware#title#apply'),
          \ function('esearch#middleware#warnings#apply'),
          \]
  endif

  " pt implicitly matches using regexp when ignore-case mode is enabled. Setting
  " case mode to 'sensitive' makes pt adapter more predictable and slightly
  " more similar to the default behavior of other adapters.
  if !has_key(g:esearch, 'case')
    if g:esearch.adapter ==# 'pt'
      let g:esearch.case = 'sensitive'
    else
      let g:esearch.case = 'ignore'
    endif
  endif

  if g:esearch#has#nvim_lua
    let g:esearch.batch_size = 5000
    let g:esearch.final_batch_size = 15000
  elseif g:esearch#has#vim_lua
    let g:esearch.batch_size = 2500
    let g:esearch.final_batch_size = 5000
  else
    let g:esearch.batch_size = 1000
    let g:esearch.final_batch_size = 4000
  endif

  return g:esearch
endfu

fu! esearch#config#default_backend() abort
  if g:esearch#has#nvim_jobs
    return 'nvim'
  elseif g:esearch#has#vim8_jobs
    return 'vim8'
  elseif g:esearch#has#vimproc()
    return 'vimproc'
  else
    return 'system'
  endif
endfu

fu! esearch#config#default_adapter() abort
  if executable('rg')
    return 'rg'
  elseif executable('ag')
    return 'ag'
  elseif executable('pt')
    return 'pt'
  elseif executable('ack')
    return 'ack'
  elseif !system('git rev-parse --is-inside-work-tree >/dev/null 2>&1') && !v:shell_error
    return 'git'
  elseif executable('grep')
    return 'grep'
  else
    throw 'No adapter executables found'
  endif
endfu

let s:root = expand( '<sfile>:p:h:h:h')
fu! s:init_lua() abort
  if g:esearch#has#nvim_lua
    lua << EOF
    esearch = require'esearch/neovim'
EOF
  elseif g:esearch#has#vim_lua
    lua << EOF
    package.path = package.path .. ';' .. vim.eval("s:root") .. '/lua/?.lua'
    esearch = require'esearch/vim'
EOF
  endif
endfu
