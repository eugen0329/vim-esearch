# Vim Easy Search

Deep development version of the vim plugin performing pseudo-async recursive search in files.  

# Usage

Type <leader>ff and insert a search pattern. Use "s", "v" and "t" buttons to open file under the
cursor in split, vertical split and in tab accordingly. Use "shift" button to open a file silently.

# Customization

Remap \<Plug\>(easysearch) to use custom easysearch entering mapping:

    map <leader>ff <Plug>(easysearch)

Also, you can use an easysearch#map() function to redefine default mappings used inside a results window.  
Here is the list of default mappings:

    call easysearch#map('<leader>ff', '<Plug>(easysearch)')
    call easysearch#map('t',          '<Plug>(easysearch-t)')
    call easysearch#map('T',          '<Plug>(easysearch-T)')
    call easysearch#map('s',          '<Plug>(easysearch-s)')
    call easysearch#map('v',          '<Plug>(easysearch-v)')
    call easysearch#map('S',          '<Plug>(easysearch-S)')
    call easysearch#map('<C-p>',      '<Plug>(easysearch-cp)')
    call easysearch#map('<C-n>',      '<Plug>(easysearch-cn)')
    call easysearch#map('<CR>',       '<Plug>(easysearch-cr)')

