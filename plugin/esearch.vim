if exists('g:loaded_esearch')
  finish
endif
let g:loaded_esearch = 1

noremap  <silent><Plug>(esearch) :<C-u>call esearch#init()<CR>
xnoremap <silent><Plug>(esearch) :<C-u>call esearch#init({'visualmode': 1})<CR>
noremap <silent><Plug>(esearch-word-under-cursor) :<C-u>call esearch#init({'use': 'word_under_cursor'})<CR>

for mapping in esearch#_mappings()
  exe 'map ' . mapping.lhs . ' ' . mapping.rhs
endfor

if !hlexists('ESearchSubstitute')
  hi link ESearchSubstitute DiffChange
endif
