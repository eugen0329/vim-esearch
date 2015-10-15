fu! easysearch#pre(visual, ...)
  if a:visual
    let initial_pattern = s:visual_selection()
  elseif get(v:, 'hlsearch', 0)
    let initial_pattern = getreg('/')
  else
    let initial_pattern = ''
  endif

  let dir = a:0 ? a:1 : $PWD
  let str = easysearch#cmdline#read(initial_pattern, dir)
  if str == ''
    return ''
  endif
  return easysearch#start(easysearch#util#escape_str(str), dir)
endfu

fu! easysearch#start(pattern, dir)
  let results_bufname = fnameescape("Search: '".a:pattern."'")

  let results_bufnr = bufnr('^'.results_bufname.'$')
  if results_bufnr > 0
    let buf_loc = s:find_buf(results_bufnr)
    if buf_loc != []
      exe 'tabn ' . buf_loc[0]
      exe buf_loc[1].'winc w'
    else
      exe 'tabnew|b ' . results_bufnr
    endif
  else
    exe 'tabnew'
    let results_bufnr = bufnr('%')
    exe "file ".results_bufname
  endif

  call easysearch#win#init()
  exe 'silent Dispatch! '.s:request_str(a:pattern, a:dir)

  let b:request = dispatch#request()
  let b:request.format = '%f:%l:%c:%m,%f:%l:%m'
  let b:request.background = 1

  let b:last_update_time = easysearch#util#timenow()
  if !easysearch#util#cgetfile(b:request)
    call easysearch#win#update(0)
  endif
endfu

fu! easysearch#mappings()
  if !exists('s:mappings')
    let s:mappings = {
          \ '<leader>ff': '<Plug>(easysearch)',
          \ 'set': function('easysearch#util#set'),
          \ 'get': function('easysearch#util#get'),
          \ 'dict': function('easysearch#util#dict'),
          \ 'with_val': function('easysearch#util#with_val'),
          \ }
  endif
  return s:mappings
endfu

fu! easysearch#map(map, plug)
  call easysearch#mappings().set(a:map, a:plug)
endfu

fu! s:request_str(pattern, dir)
  let r = g:esearch_settings.parametrize('regex')
  let c = g:esearch_settings.parametrize('case')
  let w = g:esearch_settings.parametrize('word')
  return 'ag '.r.' '.c.' '.w.' --nogroup --nocolor --column "' .
        \ a:pattern  . '" "' . a:dir . '"'
endfu

fu! s:find_buf(bufnr)
  for tabnr in range(1, tabpagenr('$'))
    if tabpagenr() == tabnr | continue | endif
    let buflist = tabpagebuflist(tabnr)
    if index(buflist, a:bufnr) >= 0
      for winnr in range(1, tabpagewinnr(tabnr, '$'))
        if buflist[winnr - 1] == a:bufnr | return [tabnr, winnr] | endif
      endfor
    endif
  endfor

  return []
endf

fu! s:visual_selection()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfu
