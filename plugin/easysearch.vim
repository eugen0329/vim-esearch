if exists('g:loaded_easy_search')
  finish
endif
let g:loaded_easy_search = 1

let g:esearch_settings = easysearch#opts#new(get(g:, 'esearch_settings', {}))

noremap <silent><Plug>(easysearch) :<C-u>call easysearch#pre(0)<CR>
xnoremap <silent><Plug>(easysearch) :<C-u>call easysearch#pre(1)<CR>

let mappings = easysearch#mappings().dict()
for map in keys(mappings)
  exe 'map ' . map . ' ' . mappings[map]
endfor

command! -nargs=1 ESearch call easysearch#start(<f-args>, $PWD)

let g:b = 0
