if exists('g:loaded_easy_search')
  finish
endif
let g:loaded_easy_search = 1

let g:esearch_settings = easysearch#opts#new(get(g:, 'esearch_settings', {}))

noremap <silent><Plug>(easysearch) :<C-u>call easysearch#pre(0)<CR>
xnoremap <silent><Plug>(easysearch) :<C-u>call easysearch#pre(1)<CR>
for map in keys(easysearch#mappings().with_val('"<Plug>(easysearch)"'))
  exe 'map ' . map .' <Plug>(easysearch)'
endfor

command! -nargs=1 ESearch call easysearch#start(<f-args>, $PWD)
