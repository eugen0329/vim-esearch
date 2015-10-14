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

Type <leader>ff and insert a search pattern. Use "s", "v" and "t" buttons to open file under the
cursor in split, vertical split and in tab accordingly. Use "shift" button to open a file silently.

# Customization

Use the following functionons to redefine default mappings.

    call easysearch#map('<leader>ff', '<Plug>(easysearch)')

    call easysearch#win#map('t',     '<Plug>(easysearch-t)')
    call easysearch#win#map('T',     '<Plug>(easysearch-T)')
    call easysearch#win#map('s',     '<Plug>(easysearch-s)')
    call easysearch#win#map('v',     '<Plug>(easysearch-v)')
    call easysearch#win#map('V',     '<Plug>(easysearch-V)')
    call easysearch#win#map('S',     '<Plug>(easysearch-S)')
    call easysearch#win#map('<C-p>', '<Plug>(easysearch-cp)')
    call easysearch#win#map('<C-n>', '<Plug>(easysearch-cn)')
    call easysearch#win#map('<CR>',  '<Plug>(easysearch-cr)')

    " Mnemonics is "(s)et (r)egex, (s)et (c)ase sesnsitive option etc.
    call easysearch#cmdline#map('<C-s><C-r>', '<Plug>(easysearch-regex)')
    call easysearch#cmdline#map('<C-s><C-c>', '<Plug>(easysearch-case)')
    call easysearch#cmdline#map('<C-s><C-w>', '<Plug>(easysearch-word)')
