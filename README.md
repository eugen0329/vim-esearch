# Vim ESearch

[![Build Status](https://travis-ci.org/eugen0329/vim-esearch.svg?branch=master)](https://travis-ci.org/eugen0329/vim-esearch)

NeoVim/Vim plugin performing project-wide async search and replace, similar to
SublimeText, Atom et al.

## Installation
ESearch has builtin support for
[The Silver Searcher](https://github.com/ggreer/the_silver_searcher#installing)(Ag),
[Ack](http://beyondgrep.com/install/),
[The Platinum Searcher](https://github.com/monochromegane/the_platinum_searcher#installation) and
native \*nix util [grep](http://linux.die.net/man/1/grep).


In your [~/.config/nvim/init.vim](https://neovim.io/doc/user/nvim_from_vim.html) or `.vimrc`:
```vim
Plugin     'eugen0329/vim-easy-search'
```

**NOTE**
[Plugin](https://github.com/VundleVim/Vundle.vim) command can be replaced with
another plugin manager you use([Plug](https://github.com/junegunn/vim-plug#installation),
[NeoBundle](https://github.com/Shougo/neobundle.vim#1-install-neobundle))

## Usage

Type `<leader>ff` and insert a search pattern (usually \<leader\> is `\`). Use `s`, `v` and `t` 
buttons to open file under the cursor in split, vertical split and in tab accordingly. Use `shift`
along with s, v and t buttons to open a file silently. Press `shift-r` to reload
currrent results.

To switch between case-sensitive/insensitive, whole-word-match and regex/literal pattern in command
line use `ctrl-s ctrl-s`, `ctrl-s ctrl-w` or `ctrl-s ctrl-r` (mnemonics is **S**et **R**egex,
**S**et ca**S**e sesnsitive option etc).

## Customization

###Mappings
In `~/.config/nvim/init.vim` / `.vimrc`:

Use the following functions to redefine default mappings:

```vim
    call esearch#map('<leader>ff', '<Plug>(esearch')

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

    call esearch#cmdline#map('<C-s><C-r>', 'toggle-regex')
    call esearch#cmdline#map('<C-s><C-s>', 'toggle-case')
    call esearch#cmdline#map('<C-s><C-w>', 'toggle-word')
    call esearch#cmdline#map('<C-s><C-h>', 'cmdline-help')
```

To redefine results match highlight use:

###Colors
```vim
hi ESearchMatch ctermfg=black ctermbg=white guifg=#000000 guibg=#E6E6FA
```

> Initialize this variable to specify preferred behaviour:

> ```vim
>     let g:esearch = {
>           \ 'regex':           0,
>           \ 'case':            0,
>           \ 'word':            0,
>           \ 'updatetime':      300.0,
>           \ 'batch_size':      2000,
>           \ 'context_width':   { 'l': 60, 'r': 60 },
>           \ 'recover_regex':   1,
>           \ 'highlight_match': 1,
>           \ 'nerdtree_plugin': 1,
>           \ 'escape_special':  1,
>           \ 'use': [ 'visual', 'hlsearch', 'last' ],
>           \ }
> ```

> | Option              |     Description                                               |
> |---------------------|---------------------------------------------------------------|
> | 'regex'             | match with regular exression (or literally)                   |
> | 'case'              | match case sensitively                                        |
> | 'word'              | only match whole words                                        |
> | 'batch_size'        | N results appended at a time                                  |
> | 'context_width'     | N chars displayed on either sides of the match                |
> | 'highlight_context' | higlight matched text with `ESearchMatch`                     |
> | 'nerdtree_plugin'   | use "Search in NERDTree directory" feature                    |
> | 'escape_special'    | escape vim special character such as #, %, \<cfile\> etc.  |
> | 'use'               | sources for the initial search value ('visual' - visual selection, 'last' - previous search expr, 'hlsearch' - currently highlighted search result). NOTE Order affects the priority  |
