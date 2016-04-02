# Vim ESearch

[![Build Status](https://travis-ci.org/eugen0329/vim-esearch.svg?branch=master)](https://travis-ci.org/eugen0329/vim-esearch)
[![Code Climate](https://codeclimate.com/github/eugen0329/vim-esearch/badges/gpa.svg)](https://codeclimate.com/github/eugen0329/vim-esearch)

NeoVim/Vim plugin performing project-wide async search and replace, similar to
SublimeText, Atom et al.

![ESearch Demo gif](https://github.com/eugen0329/vim-esearch/blob/master/.github/demo.gif)

### Features
* Builtin support for superfast engines like
[ag](https://github.com/ggreer/the_silver_searcher#installing) (_The Silver Searcher_),
[ack](http://beyondgrep.com/install/),
[pt](https://github.com/monochromegane/the_platinum_searcher#installation) (_The Platinum Searcher_) along with the
native \*nix util [grep](http://linux.die.net/man/1/grep).
* Live updating of results as in Emacs, SublimeText and similar (requires NeoVim's [job control](https://neovim.io/doc/user/job_control.html) or [vimproc](https://github.com/Shougo/vimproc.vim#install) to be installed).
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

Type `<leader>ff` and insert a search pattern (usually [\<leader>](https://neovim.io/doc/user/map.html#mapleader) is `\`). Use `s`, `v` and `t` 
buttons to open file under the cursor in split, vertical split and in tab accordingly. Use `shift`
along with s, v and t buttons to open a file silently. Press `shift-r` to reload
currrent results.

To switch between case-sensitive/insensitive, whole-word-match and regex/literal pattern in command
line use `ctrl-o ctrl-r`, `ctrl-o ctrl-s` or `ctrl-o ctrl-w` (mnemonics is set **O**ption: **R**egex,
case **S**esnsitive, **W**ord regex).

## Customization

###Mappings
In `~/.config/nvim/init.vim` / `~/.vimrc`:

Use the following functions to redefine default mappings:

```vim
    call esearch#map('<leader>ff', 'esearch')

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

To redefine results match highlight use:

###Colors

```vim
hi ESearchMatch ctermfg=black ctermbg=white guifg=#000000 guibg=#E6E6FA
```
