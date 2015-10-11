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

let g:esearch_settings = extend(get(g:, 'esearch_settings', {}), {
      \'regex': 0,
      \}, 'keep')

fu! s:easy_search(visual)
  if a:visual
    let s:cmdline = s:get_visual_selection()
  elseif get(v:, 'hlsearch', 0)
    let s:cmdline = getreg('/')
  else
    let s:cmdline = ''
  endif
  let s:cmdpos = len(s:cmdline) + 1

  let s:int_pending = 0
  while 1
    let str = input('pattern '.g:esearch_settings['regex'].'>> ', s:cmdline . s:get_correction())
    if s:int_pending | let s:int_pending = 0 | else | break | endif
  endwhile
  unlet s:int_pending

  let search_str = easysearch#util#escape_str(str)
  if search_str == ''
    return ''
  endif
  call easysearch#start(search_str)
endfu

cnoremap <C-r><C-e> <C-\>e<SID>set_search_option('regex')<CR>

fu! s:get_correction()
  if len(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(s:cmdline) + 1 - s:cmdpos )
  endif

  return ''
endfu

fu! s:set_search_option(option)
  let s:cmdline = getcmdline()
  let s:cmdpos = getcmdpos()
  let s:int_pending = 1
  call g:esearch_settings.invert(a:option)
  call feedkeys("\<C-c>", 'n')
  return ''
endfu

fu! g:esearch_settings.invert(key) dict
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu

fu! s:get_visual_selection()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfu

