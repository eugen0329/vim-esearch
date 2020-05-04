# vim-esearch

[![Build Status](https://travis-ci.org/eugen0329/vim-esearch.svg?branch=master)](https://travis-ci.org/eugen0329/vim-esearch)

Neovim/Vim plugin for **e**asy async **search** and replace across multiple files.

![ESearch Demo gif](https://raw.githubusercontent.com/eugen0329/vim-esearch/master/.github/demo.gif)

1. [Features overview](#features-overview)
2. [Install](#install)
3. [Quick start](#quick-start)
4. [Basic configuration](#basic-configuration)
5. [API](#api)
6. [Troubleshooting](#troubleshooting)
7. [Acknowledgements](#acknowledgements)
8. [Licence](#licence)

### Features overview

- Simplicity (no dependencies, pattern are auto-escaped).
- High performance:
  - Fully async functioning using neovim/vim8 jobs api.
  - Fast lua-based rendering (up to 40k lines in less than a second).
  - Viewport position-based highlights (neovim only).
  - Adaptive disabling of certain highlights on a large number of lines.
- In-place modifying and saving changes into files.
- Filetype-dependent syntax highlights for better navigation.
- Input prompt interface instead of using the commandline:
  - Search patterns can be pasted as is (try [this pattern](https://gist.github.com/gruber/8891611) with regex mode enabled by pressing `<c-r><c-r>` within the prompt).
  - Pcre-to-vim regex translation to highlight matches.
- 2 preview modes using both neovim floating windows or plain split windows.
- Interactions are done via API methods, that can be modified or reused to personalize the workflow.
- Third party plugins integration:
  - vim-visual-multi (multiple cursors plugin) is guarded from editing filenames and line numbers.
  - Most of file browsers (nerdtree, dirvish, netranger, defx) can be used to specify search paths.

### Install

Add one of the following lines depending on your plugin manager:
```vim
call   minpac#add('eugen0329/vim-esearch')
call   dein#add('eugen0329/vim-esearch')
Plug   'eugen0329/vim-esearch'
Plugin 'eugen0329/vim-esearch'
```

Optional: install [ag](https://github.com/ggreer/the_silver_searcher#installing)
or [rg](https://github.com/BurntSushi/ripgrep#installation) for faster searching
and extra features.

### Quick start

Type `<leader>ff` keys (leader is `\` unless redefined) to open the prompt. Use
`<c-r><c-r>`, `<c-s><c-s>` and `<c-t><c-t>` within the prompt to cycle through
regex, case sensitive and text-objects matching modes or use `<c-o>` to open
a menu to set searching paths, filetypes or other configs.

Within the search window use `J` and `K` to jump between entries or `{` and `}`
to jump between filenames. Use `R` to reload the results.

To open a line in a file press `<Enter>` (open in the current window), `o` (open in a split),
`s` (split vertically) or `t` to open in a new tab. Use the keys with shift
pressed (`O`, `S` and `T`) to open staying in the search window.

Modify or delete the results right inside the search window and type
`:write<CR>` to save your changes into files.

Press `p` to open a preview window. Use multiple `p` to zoom it and capital `P`
to enter the preview for express changes (without moving to a separate split window).

### Basic configuration

Configurations are scoped in `g:esearch` dictionary to make them easier to
review and to not create mess within the global namespace. Play around with
configurations below if you want to alter the default behavior.

```vim
" Use <c-f><c-f> to start the prompt, use <c-f>iw to pre-fill with the current word
" or other textobject. Try <Plug>(esearch-exec) to start a search instantly.
nmap <c-f><c-f> <Plug>(esearch)
map  <c-f>      <Plug>(esearch-prefill)

let g:esearch = {}

" Use regex matching with the smart case mode by default and avoid matching text objects.
let g:esearch.regex   = 1
let g:esearch.textobj = 0
let g:esearch.case    = 'smart'

" Set the initial pattern content using the highlighted search pattern (if
" v:hlsearch is true), the last searched pattern or the clipboard content.
let g:esearch.prefill = ['hlsearch', 'last', 'clipboard']

" Override the default files and directories to determine your project root. Set
" to blank to always use the current working directory.
let g:esearch.root_markers = ['.git', 'Makefile', 'node_modules']

" Prevent esearch from mapping any default hotkeys.
let g:esearch.default_mappings = 0

" Open the window in a vertical split and reuse it for all searches.
let g:esearch.win_new = {-> esearch#buf#goto_or_open('[Search]', 'vnew') }

" Redefine the default highlights (see :help highlight for syntax details)
highlight      esearchHeader     cterm=bold gui=bold ctermfg=white ctermbg=white
highlight link esearchStatistics esearchFilename
highlight link esearchFilename   Label
highlight      esearchMatch      ctermbg=27 ctermfg=15 guibg='#005FFF' guifg='#FFFFFF'
```

### API

Use `esearch#init({options}})` function to start a search. Specify `{options}`
dictionary using the same keys as in the global config to customize the
behavior per request.

```vim
" Search for debugger entries across the project without starting the prompt.
" Remember is set to 0 to prevent saving configs history for later searches.
nnoremap <leader>fd :call esearch#init({'pattern': '\b(ipdb\|debugger)\b', 'regex': 1, 'remember': 0})<cr>

" Search in vendor lib directories. Remember only 'regex' and 'case' modes if
" they are changed during a request.
nnoremap <leader>fs :call esearch#init({'paths': $GOPATH . ' node_modules/', 'remember': ['regex', 'case']})<cr>

" Search in front-end files using an explicitly set cwd. NOTE `set shell=bash\ -O\ globstar`
" is recommended (for OSX run `$ brew install bash` first). `-O\ extglob` is also supported.
nnoremap <leader>fe :call esearch#init({'paths': '**/*.{js,css,html}', 'cwd': '~/other-dir'})<cr>
" or if one of ag, rg or ack is available
nnoremap <leader>fe :call esearch#init({'filetypes': 'js css html', 'cwd': '~/another-dir'})<cr>

" Use callable prefiller to search go functions. Starting cursor position will be before
" the closing bracket.
let g:search_gofunc = {'prefill': [{-> "func (\<Left>"}], 'filetypes': 'go', 'select_prefilled': 0}
nnoremap <leader>fu :call esearch#init(g:search_gofunc)<cr>
```

Use `esearch_win_hook` to setup window local configurations. *NOTE* It'll automatically wrap `s:custom_esearch_config()` call to collect garbage on reloads, so no `augroup` inside is required.

```vim
autocmd User esearch_win_config call s:custom_esearch_config()

function! s:custom_esearch_config() abort
  setlocal nobuflisted    " don't show the buffer in the buffers list
  setlocal bufhidden=hide " don't unload the buffer to be able to use <c-o> jumps

  " Show the preview automatically and update it after 100ms timeout. Change
  " 'split' to 'vsplit' to open the preview vertically
  let b:preview = esearch#debounce(b:esearch.split_preview, 100)
  autocmd CursorMoved <buffer> call b:preview.apply('split')

  " Override the default vertical split mapping to open a split once and
  " reuse it for later `s` presses. The search window will remain focused
  nnoremap <silent><buffer> s  :call b:esearch.open('vnew', {'reuse': 1, 'stay': 1})<CR>
  " Yank a hovered absolute path
  nnoremap <silent><buffer> yy :let @" = b:esearch.filename()\|let @+ = @"<CR>
  " Use a custom command to open a file in a tab
  nnoremap <silent><buffer> t  :call b:esearch.open('NewTabdrop')<CR>

  " Populate the quickfix list using the current pattern
  nnoremap <silent><buffer> <leader>fq
    \ :call esearch#init({'pattern': b:esearch.pattern, 'out': 'qflist', 'remember': 0})<CR>
endfunction
```

### Troubleshooting

1. Avoid searching in `log/`, `node_modules/`, `dist/` and similar folders.

The preferred approach is to use `.agignore` for ag, `.rgignore` or similar
ignore files. To skip `node_modules` try `echo node_modules >> ~/.ignore`.

2. Git adapter have problems when searching in filenames with non-ASCII names.

Run `git config --global core.precomposeunicode true && git config --global core.quotePath false` in your shell to prevent outputting unicode chars like `\312`.

3. Some regex features like lookaround are not supported.

Use ag, ack or rg (after version 0.11) to access the PCRE syntax. Git and grep
are also support them, but sometimes require to be installed with the
corresponding flag.

4. Filetype-specific syntax highlights are missing or different than those within opened files.

The plugin uses separate syntax definitions to make the window more lightweight.
If it's misleading for you, please, disable them using `let g:esearch.win_contexts_syntax = 0` or open a PR to add or improve the existing syntax files. Highlights can also be cleared automatically if there are too many lines or if there's a long line encountered.

5. The search window is slow.

If it's sluggish during updates, try to increase `let g:esearch.win_update_throttle_wait = 200` value (100 is the default). If it's still slow after the search has finished, try to use `let g:esearch.win_contexts_syntax = 0` or consider to use neovim, as it has position-based highlights comparing to regex-based syntax matches and parses/renders results faster. Also, make sure that `echo esearch#has#lua` outputs 1.

6. Pt adapter case-insensitive mode implicitly enables regex matching mode.

Ignore case option in `pt` works by
[building a regex](https://github.com/monochromegane/the_platinum_searcher/blob/37ed028fc79f30d4de56682e26a789999ae2d561/pattern.go#L19)
so you should use case sensitive mode to match literally or switch to another adapter
like `ag` or `rg`.

### Acknowledgements

Special thanks to contributors, issue reporters and other plugin authors (arpeggio.vim, incsearch.vim etc.) whose code has helped to develop some aspects of the plugin.

### Licence

MIT
