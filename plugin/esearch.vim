if exists('g:loaded_esearch')
  finish
endif
let g:loaded_esearch = '0.1.0'

noremap  <silent><Plug>(esearch) :<C-u>call esearch#init()<CR>
xnoremap <silent><Plug>(esearch) :<C-u>call esearch#init({'visualmode': 1})<CR>
noremap  <silent><Plug>(esearch-word-under-cursor) :<C-u>call esearch#init({'prefill': ['word_under_cursor']})<CR>

let s:default_mappings = get(get(g:, 'esearch', {}), 'default_mappings', 1)
for s:mapping in esearch#_mappings()
  if !s:default_mappings && s:mapping.default | continue | endif
  exe 'map ' . s:mapping.lhs . ' ' . s:mapping.rhs
endfor
