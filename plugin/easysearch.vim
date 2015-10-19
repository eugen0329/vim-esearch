if exists('g:loaded_easy_search')
  finish
endif
let g:loaded_easy_search = 1

let g:esearch_settings = esearch#opts#new(get(g:, 'esearch_settings', {}))

noremap <silent><Plug>(esearch) :<C-u>call esearch#pre(0)<CR>
xnoremap <silent><Plug>(esearch) :<C-u>call esearch#pre(1)<CR>

let mappings = esearch#mappings().dict()
for map in keys(mappings)
  exe 'map ' . map . ' ' . mappings[map]
endfor

if !highlight_exists('EsearchMatch')
  exe "hi EsearchMatch cterm=bold gui=bold " .
        \ "ctermbg=".synIDattr(synIDtrans(hlID("DiffChange")), "bg", "cterm")." ".
        \ "ctermfg=".synIDattr(synIDtrans(hlID("DiffChange")), "fg", "cterm")." ".
        \ "guibg=" . synIDattr(synIDtrans(hlID("DiffChange")), "bg", "gui")." ".
        \ "guifg=" . synIDattr(synIDtrans(hlID("DiffChange")), "fg", "gui")." "
endif

" command! -nargs=1 ESearch call esearch#start(<f-args>, $PWD)
