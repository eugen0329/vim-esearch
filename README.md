# Vim Easy Search

Deep development version of the vim plugin performing pseudo-async recursive search in files.  


# Installation
Currently only supported ag(https://github.com/ggreer/the_silver_searcher/), so
you must to install it with by any preferred way.

In your .vimrc:

    NeoBundle  'tpope/vim-dispatch'
    NeoBundle  'eugen0329/vim-easy-search'

    Plug       'tpope/vim-dispatch'
    Plug       'eugen0329/vim-easy-search'

    Bundle     'tpope/vim-dispatch'
    Bundle     'eugen0329/vim-easy-search'

    Plugin     'tpope/vim-dispatch'
    Plugin     'eugen0329/vim-easy-search'



# Usage

Type <leader>ff and insert a search pattern. Use "s", "v" and "t" buttons to open file under the
cursor in split, vertical split and in tab accordingly. Use "shift" button to open a file silently.

# Customization

Remap \<Plug\>(easysearch) to use custom easysearch entering mapping:

    map <leader>ff <Plug>(easysearch)

Also, you can use the following functionons to redefine default mappings.

    call easysearch#map('<leader>ff', '<Plug>(easysearch)')

    call easysearch#win#map('t',          '<Plug>(easysearch-t)')
    call easysearch#win#map('T',          '<Plug>(easysearch-T)')
    call easysearch#win#map('s',          '<Plug>(easysearch-s)')
    call easysearch#win#map('v',          '<Plug>(easysearch-v)')
    call easysearch#win#map('S',          '<Plug>(easysearch-S)')
    call easysearch#win#map('<C-p>',      '<Plug>(easysearch-cp)')
    call easysearch#win#map('<C-n>',      '<Plug>(easysearch-cn)')
    call easysearch#win#map('<CR>',       '<Plug>(easysearch-cr)')


    call easysearch#cmdline#map('<Plug>(easysearch-regex)', '<C-r><C-e>')
    call easysearch#cmdline#map('<Plug>(easysearch-case)',  '<C-s>')
    call easysearch#cmdline#map('<Plug>(easysearch-word)',  '<C-t>')
