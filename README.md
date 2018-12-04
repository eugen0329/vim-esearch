# Vim ESearch

[![Build Status](https://travis-ci.org/eugen0329/vim-esearch.svg?branch=master)](https://travis-ci.org/eugen0329/vim-esearch)
[![Code Climate](https://codeclimate.com/github/eugen0329/vim-esearch/badges/gpa.svg)](https://codeclimate.com/github/eugen0329/vim-esearch)

NeoVim/Vim plugin performing project-wide async search and replace, similar to
SublimeText, Atom et al.

![ESearch Demo gif](https://raw.githubusercontent.com/eugen0329/vim-esearch/master/.github/demo.gif)

---
1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Customization](#customization)  
4.1. [General Configs](#general-configs)  
4.2. [Mappings](#mappings)  
4.3. [Colors](#colors)  

---

### Features
* Builtin support for superfast engines like
[ag](https://github.com/ggreer/the_silver_searcher#installing) (_The Silver Searcher_),
[ack](http://beyondgrep.com/install/),
[pt](https://github.com/monochromegane/the_platinum_searcher#installation) (_The Platinum Searcher_),
[rg](https://github.com/BurntSushi/ripgrep#installation) (_ripgrep_),
[git-grep](https://git-scm.com/docs/git-grep) along with the
native \*nix util [grep](http://linux.die.net/man/1/grep).
* Advanced pattern input prompt with fuzzy- and spell suggestion-driven completion.
* Live updating of results as in Emacs, SublimeText and similar (requires [Vim 8](http://vimhelp.appspot.com/eval.txt.html#Job) / [NeoVim](https://neovim.io/doc/user/job_control.html) job control or [vimproc](https://github.com/Shougo/vimproc.vim#install) to be installed).
* Special esearch window or [quickfix](https://neovim.io/doc/user/quickfix.html#quickfix) list, habitual for all, can be used as an output target.
* Search-and-Replace feature with the same syntax as builtin [:substitute](https://neovim.io/doc/user/change.html#:substitute) command (Example `:1,5ESubstitute/from/to/gc`).
* Collaborates with [nerdtree](https://github.com/scrooloose/nerdtree#intro) to provide search in a specific directory.

## Installation

In your [~/.config/nvim/init.vim](https://neovim.io/doc/user/starting.html#vimrc) or  [~/.vimrc](http://vimdoc.sourceforge.net/htmldoc/starting.html#.vimrc) :
```vim
Plugin 'eugen0329/vim-esearch'
```

**NOTE**
Plugin command (which comes with [Vundle](https://github.com/VundleVim/Vundle.vim)) can be replaced with 
another command of the plugin manager you use ([Plug](https://github.com/junegunn/vim-plug#installation),
[NeoBundle](https://github.com/Shougo/neobundle.vim#1-install-neobundle) etc.)

## Usage

Type <kbd>\<leader></kbd><kbd>f</kbd><kbd>f</kbd> and insert a search pattern (usually [\<leader>](https://neovim.io/doc/user/map.html#mapleader) is <kbd>\\</kbd>).
Use <kbd>s</kbd>, <kbd>v</kbd> and <kbd>t</kbd> buttons to open file under the
cursor in split, vertical split and in tab accordingly. Use <kbd>Shift</kbd>
along with <kbd>s</kbd>, <kbd>v</kbd> and <kbd>t</kbd> buttons to open a file silently. Press <kbd>Shift-r</kbd> to reload
currrent results.

To switch between case-sensitive/insensitive, whole-word-match and regex/literal pattern in command
line use <kbd>Ctrl-o</kbd><kbd>Ctrl-r</kbd>, <kbd>Ctrl-o</kbd><kbd>Ctrl-s</kbd> or <kbd>Ctrl-o</kbd><kbd>Ctrl-w</kbd> (mnemonics is set **O**ption: **R**egex,
case **S**esnsitive, **W**ord regex).

## Customization

### General Configs

Global ESearch configuration example:

```vim
let g:esearch = {
  \ 'adapter':          'ag',
  \ 'backend':          'vimproc',
  \ 'out':              'win',
  \ 'batch_size':       1000,
  \ 'use':              ['visual', 'hlsearch', 'last'],
  \ 'default_mappings': 1,
  \}
```

* __'adapter'__<br>
  Adapter is a system-wide executable, which is used to dispatch your search
  request. Currently available adapters are `'ag'`, `'ack'`, `'pt'`, 'rg', `'git'` and `'grep'`.
* __'backend'__<br>
  Backend is a strategy, which is used to collaborate with an adapter. Currently available:
  async backends - `'nvim'`, `'vimproc'`, `'vim8'`, and vim builtin system() func call based backend
  `'system'`<br>
  _NOTE_ `'nvim'` and `'vimproc'` requires [NeoVim](https://github.com/neovim/neovim#readme) and  [vimproc](https://github.com/Shougo/vimproc.vim#install) respectively.
* __'out'__<br>
  Results output target: `'win'` - ESearch window (see [demo](#vim-esearch)) or `'qflist'` - [quickfix](https://neovim.io/doc/user/quickfix.html#quickfix) window
* __'batch_size'__<br>
  So not to hang your vim while updating results, ESearch uses batches. Thus,
  `'batch_size'` refers to the number of result lines can be processed at one time
* __'use'__<br>
  With this option you can specify the initial search request string, which will be
  picked from a specific source. Order is relevant for priorities of this sources usage. To always start with an empty input - set this option to `[]`. Sources are:
    * `'visual'`<br>
      Selected text. Only available from the visual mode.
    * `'hlsearch'`<br>
      Current search (with /) highlight
    * `'last'`<br>
      Previously used ESearch pattern
    * `'clipboard'`<br>
      Text yanked with <kbd>y</kbd>, deleted with <kbd>s</kbd>, <kbd>l</kbd> etc.<br>
    * `'system_clipboard'`<br>
      Text you copied with <kbd>Ctrl-c</kbd> or cut with <kbd>Ctrl-x</kbd>.<br>
    * `'system_selection_clipboard'`<br>
      Text selected with mouse or other similar method (only works on Linux).<br>
    * `'word_under_cursor'`<br>
      A word under the cursor.<br>
* __'default_mappings'__<br>
  Allows you to disable default mappings. If set to `0`, no default mappings will
  be added.

### Mappings
In `~/.config/nvim/init.vim` / `~/.vimrc`:

Use the following functions to redefine default mappings (**NOTE** default
mapping are listed as an example here):

```vim
    " Start esearch prompt autofilled with one of g:esearch.use initial patterns
    call esearch#map('<leader>ff', 'esearch')
    " Start esearch autofilled with a word under the cursor
    call esearch#map('<leader>fw', 'esearch-word-under-cursor')

    call esearch#out#win#map('t',       'tab')
    call esearch#out#win#map('i',       'split')
    call esearch#out#win#map('s',       'vsplit')
    call esearch#out#win#map('<Enter>', 'open')
    call esearch#out#win#map('o',       'open')

    "    Open silently (keep focus on the results window)
    call esearch#out#win#map('T', 'tab-silent')
    call esearch#out#win#map('I', 'split-silent')
    call esearch#out#win#map('S', 'vsplit-silent')

    "    Move cursor with snapping
    call esearch#out#win#map('<C-n>', 'next')
    call esearch#out#win#map('<C-j>', 'next-file')
    call esearch#out#win#map('<C-p>', 'prev')
    call esearch#out#win#map('<C-k>', 'prev-file')

    call esearch#cmdline#map('<C-o><C-r>', 'toggle-regex')
    call esearch#cmdline#map('<C-o><C-s>', 'toggle-case')
    call esearch#cmdline#map('<C-o><C-w>', 'toggle-word')
    call esearch#cmdline#map('<C-o><C-h>', 'cmdline-help')
```

### Colors

To redefine results match highlight use:

```vim
hi ESearchMatch ctermfg=black ctermbg=white guifg=#000000 guibg=#E6E6FA
```

### Known issues
* Ignore case option in `pt` works by
[building a regex](https://github.com/monochromegane/the_platinum_searcher/blob/37ed028fc79f30d4de56682e26a789999ae2d561/pattern.go#L19)
so as a result you have implicit regexp matching here and have to escape special
characters or switch to case sensitive mode.
