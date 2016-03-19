fu! esearch#pre(visualmode, ...) abort
  let dir = a:0 ? a:1 : $PWD
  let build_opts = { 'visualmode': a:visualmode }
  let g:esearch_last_exp = esearch#regex#build(g:esearch.use, build_opts)
  let exp = esearch#cmdline#_read(g:esearch_last_exp, dir)
  if empty(exp)
    return ''
  endif
  let exp = esearch#regex#finalize(exp, g:esearch)
  return esearch#_start(exp, dir)
endfu

fu! esearch#_start(exp, dir) abort
  let pattern = g:esearch.regex ? a:exp.pcre : a:exp.literal
  let outbufname = s:outbufname(pattern)
  call esearch#out#win#init(outbufname, a:dir)

  exe 'Dispatch! '.s:request_str(pattern, a:dir)

  let b:request = dispatch#request()
  let b:request.format = '%f:%l:%c:%m,%f:%l:%m'
  let b:request.background = 1
  let b:_es_exp = a:exp

  " matchdelete moved outside in case of dynamic .highlight_match change
  if exists('b:_es_match')
    try
      call matchdelete(b:_es_match)
    catch /E803:/
    endtry
  endif
  if g:esearch.highlight_match
    let b:_es_match = matchadd('EsearchMatch', b:_es_exp.vim_match, -1)
  endif

  call esearch#out#win#update()
endfu

fu! s:outbufname(pattern) abort
  let format = s:bufname_fomat()
  let modifiers = ''
  let modifiers .= g:esearch.case ? 'c' : ''
  let modifiers .= g:esearch.word ? 'w' : ''
  let name = fnameescape(printf(format, a:pattern, modifiers))
  return substitute(name, '["]', '\\\\\0', 'g')
endfu

fu! esearch#_mappings() abort
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

fu! esearch#map(map, plug) abort
  call esearch#_mappings().set(a:map, a:plug)
endfu

fu! s:request_str(pattern, dir) abort
  let r = g:esearch.parametrize('regex')
  let c = g:esearch.parametrize('case')
  let w = g:esearch.parametrize('word')
  return "ag ".r." ".c." ".w." --nogroup --nocolor --column -- " .
        \ esearch#util#shellescape(a:pattern)  . " " . esearch#util#shellescape(a:dir)
endfu

" Results bufname format getter
fu! s:bufname_fomat() abort
  if g:esearch.regex
    if (&termencoding ==# 'utf-8' || &encoding ==# 'utf-8')
      " Since we can't use '/' in filenames
      return "Search:  \u2215%s\u2215%s"
    else
      return "Search: %%r{%s}%s"
    endif
  else
    return "Search: `%s`%s"
  endif
endfu
