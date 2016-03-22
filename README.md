## Vim ESearch

[![Build Status](https://travis-ci.org/eugen0329/vim-esearch.svg?branch=master)](https://travis-ci.org/eugen0329/vim-esearch)

Vim plugin performing pseudo-async recursive search in files using the
[the_silver_searcher](https://github.com/ggreer/the_silver_searcher#readme) backend.

**Note:** It is an alpha version yet.


## Installation
Currently only supported **Ag**, so you need to
[install](https://github.com/ggreer/the_silver_searcher#installing)
it in any of the preferred methods.

In your `.vimrc`:

If you use [NeoBundle](https://github.com/Shougo/neobundle.vim#readme):
```vim
NeoBundle  'tpope/vim-dispatch'
NeoBundle  'eugen0329/vim-easy-search'
```

If it's [Plug](https://github.com/junegunn/vim-plug#readme):

```vim
Plug       'tpope/vim-dispatch'
Plug       'eugen0329/vim-easy-search'
```

If [Vundle](https://github.com/junegunn/vim-plug#readme):

```vim
Plugin     'tpope/vim-dispatch'
Plugin     'eugen0329/vim-easy-search'
```

Or with [Pathogen](https://github.com/tpope/vim-pathogen#readme):

```bash
cd ~/.vim/bundle
git clone git@github.com:tpope/vim-dispatch.git
git clone git@github.com:eugen0329/vim-easy-search.git
```

## Usage

Type `<leader>ff` and insert a search pattern (usually \<leader\> is `\`). Use `s`, `v` and `t` 
buttons to open file under the cursor in split, vertical split and in tab accordingly. Use `shift`
along with s, v and t buttons to open a file silently. Press `shift-r` to reload
currrent results.

To switch between case-sensitive/insensitive, whole-word-match and regex/literal pattern in command
line use `ctrl-s ctrl-s`, `ctrl-s ctrl-w` or `ctrl-s ctrl-r` (mnemonics is **S**et **R**egex,
**S**et ca**S**e sesnsitive option etc).

## Customization

In you `~/.vimrc`.

Use the following functionons to redefine default mappings:

```vim
    call esearch#map('<leader>ff', '<Plug>(esearch)')

    call esearch#out#win#map('t',       '<Plug>(esearch-tab)')
    call esearch#out#win#map('i',       '<Plug>(esearch-split)')
    call esearch#out#win#map('s',       '<Plug>(esearch-vsplit)')
    call esearch#out#win#map('<Enter>', '<Plug>(esearch-open)')
    call esearch#out#win#map('o',       '<Plug>(esearch-open)')

    " Open silently (keep focus on the results window)
    call esearch#out#win#map('T',     '<Plug>(esearch-tab-s)')
    call esearch#out#win#map('I',     '<Plug>(esearch-split-s)')
    call esearch#out#win#map('S',     '<Plug>(esearch-vsplit-s)')

    " Move cursor with snapping
    call esearch#out#win#map('<C-p>', '<Plug>(esearch-prev)')
    call esearch#out#win#map('<C-n>', '<Plug>(esearch-next)')

    call esearch#cmdline#map('<C-s><C-r>', '<Plug>(esearch-regex)')
    call esearch#cmdline#map('<C-s><C-s>', '<Plug>(esearch-case)')
    call esearch#cmdline#map('<C-s><C-w>', '<Plug>(esearch-word)')
```

To redefine results match highlight use:

```vim
hi EsearchMatch ctermfg=black ctermbg=white guifg=#000000 guibg=#E6E6FA
```

Initialize this variable to specify preferred behaviour:

```vim
    let g:esearch = {
          \ 'regex':           0,
          \ 'case':            0,
          \ 'word':            0,
          \ 'updatetime':      300.0,
          \ 'batch_size':      2000,
          \ 'context_width':   { 'l': 60, 'r': 60 },
          \ 'recover_regex':   1,
          \ 'highlight_match': 1,
          \ 'nerdtree_plugin': 1,
          \ 'escape_special':  1,
          \ 'use': [ 'visual', 'hlsearch', 'last' ],
          \ }
```

| Option              |     Description                                               |
|---------------------|---------------------------------------------------------------|
| 'regex'             | match with regular exression (or literally)                   |
| 'case'              | match case sensitively                                        |
| 'word'              | only match whole words                                        |
| 'updatetime'        | results update time interval length                           |
| 'batch_size'        | N results appended at a time                                  |
| 'context_width'     | N chars displayed on either sides of the match                |
| 'highlight_context' | higlight matched text with `EsearchMatch`                     |
| 'nerdtree_plugin'   | use "Search in NERDTree directory" feature                    |
| 'escape_special'    | escape vim special character such as #, %, \<cfile\> etc.  |
| 'use'               | sources for the initial search value ('visual' - visual selection, 'last' - previous search expr, 'hlsearch' - currently highlighted search result). NOTE Order affects the priority  |
