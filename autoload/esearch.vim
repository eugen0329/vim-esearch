fu! esearch#pre(visual, ...)
  let dir = a:0 ? a:1 : $PWD
  let initial_exp = esearch#regex#new(a:visual, g:esearch_settings)
  let exp = esearch#cmdline#read(initial_exp, dir)
  if empty(exp)
    return ''
  endif
  let exp = esearch#regex#finalize(exp, g:esearch_settings)
  return esearch#start(exp, dir)
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
  let b:_es_exp = a:exp

  if g:esearch_settings.highlight_match
    let b:_es_match = matchadd('EsearchMatch', b:_es_exp.vim_match, -1)
  endif

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
        \ esearch#util#escape_str(a:pattern)  . '" "' . a:dir . '"'
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
