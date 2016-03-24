if exists('g:loaded_esearch')
  finish
endif
let g:loaded_easy_search = 1

if !has_key(g:, 'esearch#out#win#open')
  let g:esearch#out#win#open = 'tabnew'
endif

noremap  <silent><Plug>(esearch) :<C-u>call esearch#init()<CR>
xnoremap <silent><Plug>(esearch) :<C-u>call esearch#init({'visualmode': 1})<CR>

let mappings = esearch#_mappings().dict()
for map in keys(mappings)
  exe 'map ' . map . ' ' . mappings[map]
endfor

if !hlexists('ESearchSubstitute')
  hi link ESearchSubstitute DiffChange
endif
