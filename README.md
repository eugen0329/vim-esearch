# vim-esearch

[![Build Status](https://travis-ci.org/eugen0329/vim-esearch.svg?branch=master)](https://travis-ci.org/eugen0329/vim-esearch)

Neovim/Vim plugin for **e**asy async **search** and replace across multiple files.

![demo](https://raw.githubusercontent.com/eugen0329/vim-esearch/assets/main.png)

1. [Features overview](#features-overview)
2. [Install](#install)
3. [Quick start](#quick-start)
4. [Configuration](#configuration)
5. [API](#api)
6. [Troubleshooting](#troubleshooting)
7. [Acknowledgements](#acknowledgements)
8. [Licence](#licence)

### Features overview

- In-place modifying and writing changes into files.
- Updating search output on the fly while you're typing.
- Searching and viewing files from git history.
- Performance:
  - Async neovim/vim8 jobs api are used.
  - Fast lua-based rendering.
  - Viewport position-based highlights (neovim only).
  - Adaptive disabling of certain highlights on a large number of lines.
- Filetype-dependent syntax highlights for better navigation.
- Input prompt interface instead of using the commandline:
  - Search patterns can be pasted as is (try [url pattern](https://gist.github.com/gruber/8891611) with regex mode enabled by pressing `<c-r><c-r>` within the prompt).
- 2 preview modes using both neovim floating windows and plain splits.
- Third party plugins integration:
  - vim-visual-multi (multiple cursors plugin) is guarded against editing filenames and line numbers.
  - NerdTree, Dirvish, NetRanger, Fern, Defx file browsers can be used to specify search paths.

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

Type `<leader>ff` keys (leader is `\` unless redefined) to open the input prompt.

Use `<c-r><c-r>`, `<c-s><c-s>` and `<c-t><c-t>` within the prompt to cycle through
regex, case-sensitive and text-objects matching modes or use `<c-o>` to open
a menu to set searching paths, filetypes or other configs.

Within the search window use `J` and `K` to jump between entries or `{` and `}`
to jump between filenames. Use `R` to reload the results.

To open a line in a file press `<enter>` (open in the current window), `o` (open in a split),
`s` (split vertically) or `t` to open in a new tab. Use the keys with shift
pressed (`O`, `S` and `T`) to open staying in the search window.

Modify or delete results right inside the search window. Press `<enter>` in insert mode to add new lines below or above the line with results.

Use `im` and `am` text-objects to jump to the following match and start operating on it. E.g.
press `dam` to delete "a match" with trailing whitespaces under the cursor or jump to the nearest, `cim` to delete "inner match" and start
the insert mode. Use any other operator including user-defined to capture matched text. Use `.` to repeat the last change.

Use `:s/` and `:g/.../d` commands without worrying about matched layout (filenames, line numbers). They will be preserved from changes.

Type `:write<cr>` to save changes into files. Use undo and `:write<cr>` command again to revert.

Press `p` to open a preview window. Use multiple `p` to zoom and capital `P`
to enter it.

Default mappings cheatsheet:

| Keymap                                          | What it does                                                                                             |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `<leader>ff`                                    | Open the search pattern **input prompt** _[global]_                                                      |
| `<leader>f{textobj}`                            | Start a new **search for a text-object** _[global]_                                                      |
| `<c-r><c-r>` / <br> `<c-s><c-s>` / <br> `<c-t><c-t>` | Cycle through regex/case/text-object **modes** _[prompt]_                                                |
| `<c-o>`                                         | Open the **menu** _[prompt]_                                                                             |
| `<cr>` / `o` / `s` / `t`                        | **Open** a search result entry in the current window/vertical split/horizontal split/new tab _[window]_ |
| `O` / `S` / `T`                                 | Same as above, but stay in the window _[window]_                                                        |
| `K` / `J`                                       | Jump to the previous/next **search entry** _[window]_                                                   |
| `{` / `}`                                       | Jump to the previous/next **filename** _[window]_                                                       |
| `(` / `)`                                       | Jump to the previous/next filename from another **directory** _[window]_                                                       |
| `cim` / `dim` / `vim`                           | Jump to the **next match** and change/delete/select it _[window]_                                                            |
| `cam` / `dam` / `vam`                           | Same as above, but capture trailing whitespaces as well _[window]_                                      |
| `:write<cr>`                                    | **Write** changes into files _[window]_                                                                 |
| `p` / `P`                                       | Zoom/enter the **preview** window _[window]_                                                            |

### Configuration

Configurations are scoped within `g:esearch` dictionary. Play around with
key-values below if you want to alter the default behavior:

```vim
" Use <c-f><c-f> to start the prompt, use <c-f>iw to pre-fill with the current word
" or other text-objects. Try <plug>(esearch-exec) to start a search instantly.
nmap <c-f><c-f> <plug>(esearch)
map  <c-f>      <plug>(operator-esearch-prefill)

let g:esearch = {}

" Use regex matching with the smart case mode by default and avoid matching text-objects.
let g:esearch.regex   = 1
let g:esearch.textobj = 0
let g:esearch.case    = 'smart'

" Set the initial pattern content using the highlighted '/' pattern (if
" v:hlsearch is true), the last searched pattern or the clipboard content.
let g:esearch.prefill = ['hlsearch', 'last', 'clipboard']

" Override the default files and directories to determine your project root. Set it
" to blank to always use the current working directory.
let g:esearch.root_markers = ['.git', 'Makefile', 'node_modules']

" Prevent esearch from adding any default keymaps.
let g:esearch.default_mappings = 0

" Start the search only when the enter is hit instead of updating the pattern while you're typing.
let g:esearch.live_update = 0

" Open the search window in a vertical split and reuse it for all further searches.
let g:esearch.name = '[esearch]'
let g:esearch.win_new = {esearch -> esearch#buf#goto_or_open(esearch.name, 'vnew')}

" Redefine the default highlights (see :help highlight and :help esearch-appearance)
highlight      esearchHeader     cterm=bold gui=bold ctermfg=white ctermbg=white
highlight link esearchStatistics esearchFilename
highlight link esearchFilename   Label
highlight      esearchMatch      ctermbg=27 ctermfg=15 guibg='#005FFF' guifg='#FFFFFF'
```

### API

![autopreview demo](https://raw.githubusercontent.com/eugen0329/vim-esearch/assets/autopreview.png)

Automatically update the preview for the entry under the cursor.
*NOTE* It'll internally wrap `CursorMoved` autocommand to collect garbage on reloads, so no `augroup` around is required.
```vim
autocmd User esearch_win_config
  \  let b:autopreview = esearch#async#debounce(b:esearch.preview_open, 100)
  \| autocmd CursorMoved <buffer> call b:autopreview.apply({'align': 'right'})
```

![git-grep demo](https://raw.githubusercontent.com/eugen0329/vim-esearch/assets/git-grep-demo.png)

Define `<leader>fh` keymap for searching in git history and define a popup with `git-show` output. Use `P` to maximize and enter the popup for viewing the patch.
```vim
" Show the popup with git-show information on CursorMoved is a git revision context is hovered.
let g:GitShow = {ctx -> ctx().rev &&
  \ esearch#preview#shell('git show ' . split(ctx().filename, ':')[0], {
  \   'let': {'&filetype': 'git', '&number': 0},
  \   'row': screenpos(0, ctx().begin, 1).row,
  \   'col': screenpos(0, ctx().begin, col([ctx().begin, '$'])).col,
  \   'width': 47, 'height': 3,
  \ })
  \}
" Debounce the popup updates using 70ms timeout.
autocmd User esearch_win_config
      \  let b:git_show = esearch#async#debounce(g:GitShow, 70)
      \| autocmd CursorMoved <buffer> call b:git_show.apply(b:esearch.ctx)

nnoremap <leader>fh :call esearch#init({'paths': esearch#xargs#git_log()})<cr>
```
Other git usage examples.
```vim
" Search in modified files only
nnoremap <leader>fm :call esearch#init({'paths': '`git ls-files --modified`'})<cr>
" Search in unmerged commits using range specification
nnoremap <leader>fu :call esearch#init({'paths': esearch#xargs#git_log('development..HEAD')})<cr>
" Search in stashed entries
nnoremap <leader>fs :call esearch#init({'paths': esearch#xargs#git_stash()})<cr>
```

In place of the built-in git blobs viewer, it's also possible to use custom functions from other plugins to have advanced features.
Although, they are generally slower, so if autopreview is used, it's recommended to use the built-ins.

```vim
let g:esearch.git_dir = {cwd -> FugitiveExtractGitDir(cwd)}
let g:esearch.git_url = {path, dir -> FugitiveFind(path, dir)}
```

![floating demo](https://raw.githubusercontent.com/eugen0329/vim-esearch/assets/floating.png)

Use a popup-like floating window to render search results.

```vim
let g:esearch = {}
" Try to jump into the opened floating window or open a new one.
let g:esearch.win_new = {esearch ->
  \ esearch#buf#goto_or_open(esearch.name, {name ->
  \   nvim_open_win(bufadd(name), v:true, {
  \     'relative': 'editor',
  \     'row': &lines / 10,
  \     'col': &columns / 10,
  \     'width': &columns * 8 / 10,
  \     'height': &lines * 8 / 10
  \   })
  \ })
  \}
" Close the floating window when opening an entry.
autocmd User esearch_win_config autocmd BufLeave <buffer> quit
```

Customize writing behavior by redefining the callback that is invoked after applying changes into files.

```vim
" Save applied changes if :write! with '!' was used. Open modified buffers otherwise.
let g:esearch.write_cb = {buf, bang -> bang ? buf.write(bang) : buf.open('$tabnew')}

" Save silently and wipeout buffers if they didn't exist.
let g:esearch.write_cb = {buf, bang -> buf.write(bang) && (!buf.existed && buf.bwipeout())}

" Append buffers data to a location list for reviewing, open it and edit the first entry.
let g:esearch.write_cb = {buf, bang -> setloclist(winnr(), [buf], 'a')}
autocmd User esearch_write_post lopen | wincmd p | lfirst
```

Use `esearch#init({options}})` and `esearch#prefill({options}})` functions to start a new search. Specify `{options}`
dictionary using the same keys as in the global config to customize the
behavior per request. Examples:

```vim
" Search for debugger statements instantly (without starting the prompt).
nnoremap <leader>fd :call esearch#init({'pattern': '\b(ipdb\|debugger)\b', 'regex': 1})<cr>

" Search in front-end files using explicitly set paths.
" NOTE It requires `set shell=bash\ -O\ globstar\ -O\ extglob` and GNU bash available
" (type `$ brew install bash` if OSX is used).
nnoremap <leader>fe :call esearch#init({'paths': '**/*.{js,css,html}'})<cr>
" or if one of ag, rg or ack is available
nnoremap <leader>fe :call esearch#init({'filetypes': 'js css html'})<cr>

" Use a callable prefiller to search python functions.
" Rough equivalent of 'def ${VISUAL}$0(' expansion in snippets.
vnoremap <expr><leader>fp esearch#prefill({'prefill': [{VISUAL-> "def ".VISUAL()."(\<left>"}]})
nnoremap <leader>fp :call esearch#init({'prefill': [{VISUAL-> "def ".VISUAL()."(\<left>"}]})<cr>

" esearch#prefill() can be used as an operator. Use '<leader>fl' in visual mode or with
" a text-object like '<leader>fli(' to search for the selected text in lib directories.
noremap  <expr><leader>fl  esearch#prefill({'paths': $GOPATH.' node_modules/'})
nnoremap <leader>fll :call esearch#init({'paths': $GOPATH.' node_modules/'})<cr>
```

Add window-local keymaps using `g:esearch.win_map` list.

```vim
"   Keymap |     What it does
" ---------+---------------------------------------------------------------------------------------------
"    yf    | Yank a hovered file absolute path.
"    t     | Use a custom command to open the file in a tab.
"    +     | Render [count] more lines after a line with matches. Ex: + adds 1 line, 10+ adds 10.
"    -     | Render [count] less lines after a line with matches. Ex: - hides 1 line, 10- hides 10.
"    gq    | Populate QuickFix list using results of the current pattern search.
"    gsp   | Sort the results by path. NOTE that it's search util-specific.
"    gsd   | Sort the results by modification date. NOTE that it's search util-specific.

" Each definition contains nvim_set_keymap() args: [{modes}, {lhs}, {rhs}].
let g:esearch.win_map = [
 \ ['n', 'yf',  ':call setreg(esearch#util#clipboard_reg(), b:esearch.filename())<cr>'],
 \ ['n', 't',   ':call b:esearch.open("NewTabdrop")<cr>'                              ],
 \ ['n', '+',   ':call esearch#init(extend(b:esearch, AddAfter(+v:count1)))<cr>'      ],
 \ ['n', '-',   ':call esearch#init(extend(b:esearch, AddAfter(-v:count1)))<cr>'      ],
 \ ['n', 'gq',  ':call esearch#init(extend(copy(b:esearch), {"out": "qflist"}))<cr>'  ],
 \ ['n', 'gsp', ':call esearch#init(extend(b:esearch, sort_by_path))<cr>'             ],
 \ ['n', 'gsd', ':call esearch#init(extend(b:esearch, sort_by_date))<cr>'             ],
 \]

" Helpers to use in keymaps.
let g:sort_by_path = {'adapters': {'rg': {'options': '--sort path'}}}
let g:sort_by_date = {'adapters': {'rg': {'options': '--sort modified'}}}
" {'backend': 'system'} means synchronous reload using system() call to stay within the
" same context
let g:AddAfter = {n -> {'after': b:esearch.after + n, 'backend': 'system'}}
```

See `:help esearch-api` and `:help esearch-api-examples` for more details.

### Troubleshooting

1. Avoid searching in `log/`, `node_modules/`, `dist/` and similar folders.

The preferred approach is to use `.agignore` for ag, `.rgignore` or similar
ignore files. To skip `node_modules` try `echo node_modules >> ~/.ignore`.

2. Git adapter have problems when searching in filenames with non-ASCII names.

Run `git config --global core.precomposeunicode true && git config --global core.quotePath false` in your shell to prevent outputting unicode chars like `\312`.

3. Some regex features like lookaround are not supported.

Use ag, ack or rg (of version >= 0.11) to access PCRE syntax. Git and grep
are also support them, but sometimes require to be installed with the
corresponding flag.

4. Filetype-specific syntax highlights are missing or different from those within opened files.

The plugin uses separate syntax definitions to make the window more lightweight.
If it's misleading for you, please, disable them using `let g:esearch.win_contexts_syntax = 0` or open a PR to add or improve the existing syntax files. Highlights can also be cleared automatically if there are too many lines or if there's a long line encountered.

5. The search window is slow.

If it's sluggish during updates, try to increase `let g:esearch.win_update_throttle_wait = 200` value (100 is the default). If it's still slow after the search has finished, try to use `let g:esearch.win_contexts_syntax = 0` or consider to use neovim, as it has position-based highlights comparing to regex-based syntax matches and parses/renders results faster. Also, make sure that `echo esearch#has#lua` outputs 1.

See `:help esearch-troubleshooting` for more troubleshooting examples.

### Acknowledgements

Special thanks to contributors, issue reporters and other plugin authors (vital.vim, arpeggio.vim, incsearch.vim etc.) whose code has helped to develop some aspects of the plugin.

### Licence

MIT
