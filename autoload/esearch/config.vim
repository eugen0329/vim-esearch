fu! esearch#config#eager() abort
  if !exists('g:esearch')
    let g:esearch = {}
  endif

  if !get(g:esearch, 'loaded_lazy', 0)
    call esearch#util#doautocmd('User eseach_config_eager_pre')
    call esearch#config#init(g:esearch)
    call s:lua_init()
    call esearch#highlight#init()
    let g:esearch.loaded_lazy = 1
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
        \ 'paths':                                 esearch#shell#argv([]),
        \ 'filetypes':                             '',
        \ 'after':                                 0,
        \ 'before':                                0,
        \ 'context':                               0,
        \ 'early_finish_wait':                     80,
        \ 'default_mappings':                      1,
        \ 'root_markers':                          ['.git', '.hg', '.svn', '.bzr', '_darcs'],
        \ 'errors':                                [],
        \ 'prefill':                               ['hlsearch', 'current', 'last'],
        \ 'select_prefilled':                      1,
        \ 'parse_strategy':                        g:esearch#has#lua ? 'lua' : 'viml',
        \ 'win_render_strategy':                   g:esearch#has#lua ? 'lua' : 'viml',
        \ 'win_update_throttle_wait':              g:esearch#has#throttle ? 100 : 0,
        \ 'win_viewport_off_screen_margin':        &lines > 100 ? &lines : 100,
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
        \ 'filemanager_integration':               1,
        \ 'pending_deprecations':                  [],
        \}, 'keep')
  let g:esearch = extend(g:esearch, {
        \ 'win_ui_nvim_syntax':                       g:esearch.win_render_strategy ==# 'lua' && g:esearch#has#nvim_lua_syntax,
        \ 'win_contexts_syntax_clear_on_files_count': g:esearch.win_matches_highlight_strategy ==# 'viewport' ? 1000 : 200,
        \}, 'keep')

  if !has_key(g:esearch, 'middleware')
    let g:esearch.middleware = [
          \ function('esearch#middleware#deprecations#apply'),
          \ function('esearch#middleware#id#apply'),
          \ function('esearch#middleware#adapter#apply'),
          \ function('esearch#middleware#cwd#apply'),
          \ function('esearch#middleware#paths#apply'),
          \ function('esearch#middleware#filemanager#apply'),
          \ function('esearch#middleware#prewarm#apply'),
          \ function('esearch#middleware#pattern#apply'),
          \ function('esearch#middleware#exec#apply'),
          \ function('esearch#middleware#remember#apply'),
          \ function('esearch#middleware#title#apply'),
          \ function('esearch#middleware#warnings#apply'),
          \]
  endif

  if g:esearch.default_mappings
    let g:esearch.win_map = extend([
          \ ['n',  'R',    '<Plug>(esearch-win-reload)',           ],
          \ ['n',  't',    '<Plug>(esearch-win-tabopen)',          ],
          \ ['n',  'T',    '<Plug>(esearch-win-tabopen:stay)',     ],
          \ ['n',  'o',    '<Plug>(esearch-win-split)',            ],
          \ ['n',  'O',    '<Plug>(esearch-win-split:reuse:stay)', ],
          \ ['n',  's',    '<Plug>(esearch-win-vsplit)',           ],
          \ ['n',  'S',    '<Plug>(esearch-win-vsplit:reuse:stay)',],
          \ ['n',  '<CR>', '<Plug>(esearch-win-open)',             ],
          \ ['n',  'p',    '<Plug>(esearch-win-preview)',          ],
          \ ['n',  'P',    '<Plug>(esearch-win-preview:enter)',    ],
          \ [' ',  'J',    '<Plug>(esearch-win-jump:entry:down)'   ],
          \ [' ',  'K',    '<Plug>(esearch-win-jump:entry:up)'     ],
          \ [' ',  '}',    '<Plug>(esearch-win-jump:filename:down)'],
          \ [' ',  '{',    '<Plug>(esearch-win-jump:filename:up)'  ],
          \ ['ov', 'im',   '<Plug>(textobj-esearch-match-i)',      ],
          \ ['ov', 'am',   '<Plug>(textobj-esearch-match-a)',      ],
          \ ['c',  '<CR>', '<Plug>(esearch-win-CR)', {'nowait': 1} ],
          \], get(g:esearch, 'win_map', []))
  else
    let g:esearch.win_map = get(g:esearch, 'win_map', [])
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
    let g:esearch.batch_size       = get(g:esearch, 'batch_size', 5000)
    let g:esearch.final_batch_size = get(g:esearch, 'final_batch_size', 15000)
  elseif g:esearch#has#vim_lua
    let g:esearch.batch_size       = get(g:esearch, 'batch_size', 2500)
    let g:esearch.final_batch_size = get(g:esearch, 'final_batch_size', 5000)
  else
    let g:esearch.batch_size       = get(g:esearch, 'batch_size', 1000)
    let g:esearch.final_batch_size = get(g:esearch, 'final_batch_size', 4000)
  endif

  return g:esearch
endfu

fu! esearch#config#default_backend() abort
  if g:esearch#has#nvim_jobs
    return 'nvim'
  elseif g:esearch#has#vim8_jobs
    return 'vim8'
  else
    return 'system'
  endif
endfu

" RG is probably the fastest, but has support of pcre only in later versions.
" Ag seems to support only pcre of version 1 yet, which has promblems with unicode.
" Unlike pt, Ack doesn't have side effects like enabling regexp mode when case
" == 'sensitive' is used and it supports filetypes matching. Git searches only
" in the tracked files. --untracked options seems not working.
fu! esearch#config#default_adapter() abort
  if executable('rg')
    return 'rg'
  elseif executable('ag')
    return 'ag'
  elseif executable('ack')
    return 'ack'
  elseif executable('pt')
    return 'pt'
  elseif !system('git rev-parse --is-inside-work-tree') && !v:shell_error
    return 'git'
  elseif executable('grep')
    return 'grep'
  else
    throw 'No adapter executables found'
  endif
endfu

let s:root = expand( '<sfile>:p:h:h:h')
fu! s:lua_init() abort
  if !g:esearch#has#lua | return | endif

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
