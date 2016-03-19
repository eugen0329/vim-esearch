fu! esearch#pre(visualmode, ...) abort
  if a:0
    let options = a:1
    let dir = get(options, 'dir', $PWD)
  else
    let dir = $PWD
  endif

  let g:esearch.last_exp = esearch#regex#build(g:esearch.use, {'visualmode': a:visualmode})

  let exp = esearch#cmdline#_read(g:esearch.last_exp, dir)
  if empty(exp)
    return ''
  endif
  let exp = esearch#regex#finalize(exp, g:esearch)
  return esearch#_start(exp, dir, g:esearch#out#win#open)
endfu

fu! esearch#_start(exp, dir, opencmd) abort
  let pattern = g:esearch.regex ? a:exp.pcre : a:exp.literal

  call esearch#out#{g:esearch.out}#init(g:esearch.backend, a:exp, s:outbufname(pattern), a:dir, a:opencmd)
  call esearch#backend#{g:esearch.backend}#init(s:request_str(pattern, a:dir))
  silent call esearch#out#{g:esearch.out}#update()
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
