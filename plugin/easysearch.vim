if exists('g:loaded_easy_search')
  finish
endif
let g:loaded_easy_search = 1

noremap <silent><Plug>(easysearch) :<C-u>call <SID>easy_search(0)<CR>
xnoremap <silent><Plug>(easysearch) :<C-u>call <SID>easy_search(1)<CR>

command! -nargs=1 ESearch call easysearch#start(<f-args>)

if !hasmapto('<Plug>(easymotion-prefix)')
  map <leader>ff <Plug>(easysearch)
endif

fu! s:easy_search(visual)
  if a:visual
    let initial_search_val = s:get_visual_selection()
  else
    let initial_search_val = ''
  endif

  let search_str = s:escape_search_string(input('pattern >>> ', initial_search_val))
  if search_str == ''
    return ''
  endif
  call easysearch#start(search_str)
endfu

fu! s:escape_search_string(str)
  return substitute(a:str, '["#$%]', '\\\0', 'g')
endfu

function! s:get_visual_selection()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction


