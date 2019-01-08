if exists('g:loaded_esearch')
  finish
endif
let g:loaded_esearch = 1

noremap  <silent><Plug>(esearch) :<C-u>call esearch#init()<CR>
xnoremap <silent><Plug>(esearch) :<C-u>call esearch#init({'visualmode': 1})<CR>
noremap <silent><Plug>(esearch-word-under-cursor) :<C-u>call esearch#init({'use': 'word_under_cursor'})<CR>

let s:default_mappings = get(get(g:, 'esearch', {}), 'default_mappings', g:esearch#defaults#default_mappings)
for mapping in esearch#_mappings()
  if !s:default_mappings && mapping.default | continue | endif
  exe 'map ' . mapping.lhs . ' ' . mapping.rhs
endfor

if !hlexists('ESearchSubstitute')
  hi link ESearchSubstitute DiffChange
endif
