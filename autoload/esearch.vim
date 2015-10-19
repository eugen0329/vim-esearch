fu! esearch#pre(visual, ...)
  let dir = a:0 ? a:1 : $PWD
  let exp = esearch#cmdline#read(s:initial_pattern(a:visual), dir)
  if empty(exp)
    return ''
  endif
  return esearch#start(exp, dir)
endfu

fu! s:initial_pattern(visual)
  if a:visual && g:esearch_settings.use.visual
    let v = s:visual_selection()
    return { 'vim': v, 'pcre': v, 'literal': v }
  elseif get(v:, 'hlsearch', 0) && g:esearch_settings.use.hlsearch
    let v = getreg('/')
    return { 'vim': v,
          \ 'pcre': esearch#regex#vim2pcre(v),
          \ 'literal': esearch#regex#vim_sanitize(v)
          \ }
  else
    return { 'vim': '', 'pcre': '', 'literal': '' }
  endif
endfu

fu! esearch#start(exp, dir)
  let pattern = g:esearch_settings.regex ? a:exp.pcre : a:exp.literal
  let results_bufname = escape(fnameescape("Search: `".pattern."`"), '.')
  call s:find_or_create_buf(results_bufname)
  call esearch#win#init()

  exe 'silent Dispatch! '.s:request_str(pattern, a:dir)

  let b:request = dispatch#request()
  let b:request.format = '%f:%l:%c:%m,%f:%l:%m'
  let b:request.background = 1
  let b:exp = a:exp

  if g:esearch_settings.highlight_match
    call s:hlmatch()
  endif

  if !esearch#util#cgetfile(b:request)
    call esearch#win#update()
  endif
endfu

fu! s:hlmatch()
  let p = b:exp.vim
  if g:esearch_settings.word
    let p = '\%(\<\|\>\)'.p.'\%(\<\|\>\)'
  endif
  if !g:esearch_settings.case
    let p = '\c'.p
  endif
  let p = '\%>2l\s\+\d\+\s.*\zs'.p
  let b:esearch_match = matchadd('EsearchMatch', p)
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
