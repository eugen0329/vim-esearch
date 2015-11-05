## Vim Easy Search

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
along with s, v and t buttons to open a file silently.

To switch between case-sensitive/insensitive, whole-word-match and regex/literal pattern in command
line use `ctrl-s ctrl-c`, `ctrl-s ctrl-w` or `ctrl-s ctrl-r` (mnemonics is **S**et **R**egex,
**S**et **C**ase sesnsitive option etc).

## Customization

In you `~/.vimrc`.

Use the following functionons to redefine default mappings:

```vim
    call esearch#map('<leader>ff', '<Plug>(esearch)')

    call esearch#win#map('t',     '<Plug>(esearch-t)')
    call esearch#win#map('T',     '<Plug>(esearch-T)')
    call esearch#win#map('s',     '<Plug>(esearch-s)')
    call esearch#win#map('v',     '<Plug>(esearch-v)')
    call esearch#win#map('V',     '<Plug>(esearch-V)')
    call esearch#win#map('S',     '<Plug>(esearch-S)')
    call esearch#win#map('<C-p>', '<Plug>(esearch-cp)')
    call esearch#win#map('<C-n>', '<Plug>(esearch-cn)')
    call esearch#win#map('<CR>',  '<Plug>(esearch-cr)')

    call esearch#cmdline#map('<C-s><C-r>', '<Plug>(esearch-regex)')
    call esearch#cmdline#map('<C-s><C-c>', '<Plug>(esearch-case)')
    call esearch#cmdline#map('<C-s><C-w>', '<Plug>(esearch-word)')
```

To redefine results match highlight use:

```vim
hi EsearchMatch ctermfg=black ctermbg=white guifg=#000000 guibg=#E6E6FA
```

Initialize this variable to specify preferred behaviour:

```vim
    let g:esearch_settings = {
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
          \ 'use': { 
          \   'visual': 1,
          \   'hlsearch': 1
          \   },
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
| 'escape_special'    | escape vim special character such as #, %, <cfile> etc.  |
| 'use'               | sources for the initial search value ('visual' - visual selection, 'hlsearch' - currently highlighted search result)  |
