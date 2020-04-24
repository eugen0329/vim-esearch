fu! s:default(var, default) abort
  if exists(a:var) | return | endif
  let {a:var} = a:default
endfu
call s:default('g:esearch_win_highlight_debounce_wait',                   100)
call s:default('g:esearch_win_highlight_viewport_margin',                 100)
call s:default('g:esearch_win_matches_highlight_debounce_wait',           100)
call s:default('g:esearch_out_win_highlight_matches',                     (g:esearch#has#nvim_lua_syntax ? 'viewport' : 'matchadd'))
call s:default('g:esearch_win_disable_context_highlights_on_files_count', (g:esearch_out_win_highlight_matches ==# 'viewport' ? 800 : 200))
call s:default('g:esearch_win_update_using_timer',                        1)
call s:default('g:esearch#out#win#context_syntax_highlight',              1)
call s:default('g:esearch#out#win#context_syntax_max_lines',              500)
call s:default('g:esearch_win_updates_timer_wait_time',                   100)
call s:default('g:esearch_out_win_highlight_cursor_line_number',          g:esearch#has#virtual_cursor_linenr_highlight)
call s:default('g:esearch_out_win_render_using_lua',                      g:esearch#has#lua)
call s:default('g:esearch_out_win_nvim_lua_syntax',                       g:esearch_out_win_render_using_lua && g:esearch#has#nvim_lua_syntax)
call s:default('g:unload_context_syntax_on_line_length',                  500)
call s:default('g:unload_global_syntax_on_line_length',                   30000)
call s:default('g:esearch#out#win#open',                                  'tabnew')
call s:default('g:esearch#out#win#buflisted',                             0)
call s:default('g:esearch_win_results_len_annotations',                   g:esearch#has#virtual_text)

fu! esearch#config#init() abort
  if !exists('g:esearch')
    let g:esearch = {}
  endif

  if !get(g:esearch, 'lazy_loaded', 0)
    let g:esearch = esearch#config#new(g:esearch)
    call s:init_lua()
    let g:esearch.lazy_loaded = 1
  endif

  return 0
endfu

fu! esearch#config#new(opts) abort
  let opts = copy(a:opts)

  if !has_key(opts, 'backend')
    if g:esearch#has#nvim_jobs
      let opts.backend = 'nvim'
    elseif g:esearch#has#vim8_jobs
      let opts.backend = 'vim8'
    elseif g:esearch#has#vimproc()
      let opts.backend = 'vimproc'
    else
      let opts.backend = 'system'
    endif
  endif

  if !has_key(opts, 'adapter')
    let opts.adapter = esearch#config#default_adapter()
  endif

  if g:esearch#has#nvim_lua
    let batch_size = 5000
    let final_batch_size = 15000
  elseif g:esearch#has#vim_lua
    let batch_size = 2500
    let final_batch_size = 5000
  else
    let batch_size = 1000
    let final_batch_size = 4000
  endif

  " pt implicitly matches using regexp when ignore-case mode is enabled. Setting
  " case mode to 'sensitive' makes pt adapter more predictable and slightly
  " more similar to the default behavior of other adapters.
  if !has_key(opts, 'case')
    if opts.adapter ==# 'pt'
      let opts.case = 'sensitive'
    else
      let opts.case = 'ignore'
    endif
  endif

  " root_markers are made to correspond g:ctrlp_root_markers default value
  let opts = extend(opts, {
        \ 'last_id':          0,
        \ 'out':              'win',
        \ 'regex':            'literal',
        \ 'textobj':          'none',
        \ 'adapters':         {},
        \ 'batch_size':       batch_size,
        \ 'final_batch_size': final_batch_size,
        \ 'context_width':    { 'left': 60, 'right': 60 },
        \ 'after':            0,
        \ 'before':           0,
        \ 'context':          0,
        \ 'early_finish_timeout': 50,
        \ 'default_mappings': 1,
        \ 'nerdtree_plugin':  1,
        \ 'root_markers':     ['.git', '.hg', '.svn', '.bzr', '_darcs'],
        \ 'slice':            function('esearch#util#slice'),
        \ 'errors':           [],
        \ 'use':              ['visual', 'current', 'hlsearch', 'last'],
        \}, 'keep')

  return opts
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
    throw 'No executables found'
  endif
endfu

let s:root = expand( '<sfile>:p:h:h:h')
fu! s:init_lua()
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
