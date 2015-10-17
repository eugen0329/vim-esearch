fu! esearch#pre(visual, ...)
  if a:visual && g:esearch_settings.use.visual
    let initial_pattern = s:visual_selection()
  elseif get(v:, 'hlsearch', 0) && g:esearch_settings.use.hlsearch
    let initial_pattern = getreg('/')
  else
    let initial_pattern = ''
  endif

  let dir = a:0 ? a:1 : $PWD
  let str = esearch#cmdline#read(initial_pattern, dir)
  if str == ''
    return ''
  endif
  return esearch#start(esearch#util#escape_str(str), dir)
endfu

fu! esearch#start(pattern, dir)
  let results_bufname = escape(fnameescape("Search: `".a:pattern."`"), '.')
  call s:find_or_create_buf(results_bufname)
  call esearch#win#init()
  exe 'silent Dispatch! '.s:request_str(a:pattern, a:dir)

  let b:request = dispatch#request()
  let b:request.format = '%f:%l:%c:%m,%f:%l:%m'
  let b:request.background = 1

  if !esearch#util#cgetfile(b:request)
    call esearch#win#update()
  endif
endfu

fu! esearch#mappings()
  if !exists('s:mappings')
    let s:mappings = {
          \ '<leader>ff': '<Plug>(esearch)',
          \ 'set': function('esearch#util#set'),
          \ 'get': function('esearch#util#get'),
          \ 'dict': function('esearch#util#dict'),
          \ 'with_val': function('esearch#util#with_val'),
          \ }
  endif
  return s:mappings
endfu

fu! esearch#map(map, plug)
  call esearch#mappings().set(a:map, a:plug)
endfu

fu! s:request_str(pattern, dir)
  let r = g:esearch_settings.parametrize('regex')
  let c = g:esearch_settings.parametrize('case')
  let w = g:esearch_settings.parametrize('word')
  return 'ag '.r.' '.c.' '.w.' --nogroup --nocolor --column "' .
        \ a:pattern  . '" "' . a:dir . '"'
endfu

fu! s:find_or_create_buf(bufname)
  let bufnr = bufnr('^'.a:bufname.'$')
  if bufnr > 0
    let buf_loc = s:find_buf(bufnr)
    if empty(buf_loc)
      exe 'tabnew|b ' . bufnr
    else
      exe 'tabn ' . buf_loc[0]
      exe buf_loc[1].'winc w'
    endif
  else
    exe 'tabnew|file '.a:bufname
  endif
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
