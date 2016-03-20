if exists('g:loaded_easy_search')
  finish
endif
let g:loaded_easy_search = 1

let g:esearch = esearch#opts#new(get(g:, 'esearch', {}))

if !has_key(g:, 'esearch#out#win#open')
  let g:esearch#out#win#open = 'tabnew'
endif

noremap <silent><Plug>(esearch) :<C-u>call esearch#pre(0)<CR>
xnoremap <silent><Plug>(esearch) :<C-u>call esearch#pre(1)<CR>

let mappings = esearch#_mappings().dict()
for map in keys(mappings)
  exe 'map ' . map . ' ' . mappings[map]
endfor

hi link ESearchSubstitute DiffChange
