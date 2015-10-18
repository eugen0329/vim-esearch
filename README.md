# Vim Easy Search

Vim plugin performing pseudo-async recursive search in files.


# Installation
Currently only supported [Ag](https://github.com/ggreer/the_silver_searcher#readme), so
you must to install it in any of the preferred methods.

In your .vimrc:

    " If you use NeoBundle
    NeoBundle  'tpope/vim-dispatch'
    NeoBundle  'eugen0329/vim-easy-search'

    " If you use Plug
    Plug       'tpope/vim-dispatch'
    Plug       'eugen0329/vim-easy-search'

    " If your plugin manager is Vundle
    Plugin     'tpope/vim-dispatch'
    Plugin     'eugen0329/vim-easy-search'

Or with Pathogen:

    cd ~/.vim/bundle
    git clone git@github.com:tpope/vim-dispatch.git
    git clone git@github.com:eugen0329/vim-easy-search.git


# Usage

Type \<leader\>ff and insert a search pattern. Use "s", "v" and "t" buttons to open file under the
cursor in split, vertical split and in tab accordingly. Use "shift" button to open a file silently.

# Customization

Use the following functionons to redefine default mappings.

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

    " Mnemonics is "(s)et (r)egex, (s)et (c)ase sesnsitive option etc.
    call esearch#cmdline#map('<C-s><C-r>', '<Plug>(esearch-regex)')
    call esearch#cmdline#map('<C-s><C-c>', '<Plug>(esearch-case)')
    call esearch#cmdline#map('<C-s><C-w>', '<Plug>(esearch-word)')
