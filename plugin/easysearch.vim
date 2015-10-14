if exists('g:loaded_easy_search')
  finish
endif
let g:loaded_easy_search = 1

let g:esearch_settings = easysearch#opts#new(get(g:, 'esearch_settings', {}))

noremap <silent><Plug>(easysearch) :<C-u>call easysearch#pre(0)<CR>
xnoremap <silent><Plug>(easysearch) :<C-u>call easysearch#pre(1)<CR>
if !hasmapto('<Plug>(easymotion-prefix)')
  map <leader>ff <Plug>(easysearch)
endif

command! -nargs=1 ESearch call easysearch#start(<f-args>)
