fu! esearch#init(...)
  let opts = a:0 ? a:1 : {}
  let source_params = {'visualmode': get(opts, 'visualmode', 0)}
  let g:esearch.last_exp = esearch#source#pick_exp(g:esearch.use, source_params)

  call extend(opts, {
        \ 'set_default': function('esearch#util#set_default'),
        \ 'require': function('esearch#util#require')
        \})

  call opts.set_default('cwd', $PWD)
  call opts.set_default('adapter', g:esearch.adapter)

  if !has_key(opts, 'exp')
    let opts.exp = esearch#cmdline#_read(g:esearch.last_exp, opts.cwd, esearch#adapter#{opts.adapter}#options())
    if empty(opts.exp)
      return 1
    endif
    let opts.exp = esearch#regex#finalize(opts.exp, g:esearch)
  endif

  let pattern = g:esearch.regex ? opts.exp.pcre : opts.exp.literal
  let cmd = esearch#adapter#{opts.adapter}#cmd(pattern, opts.cwd)

  call opts.set_default('backend', g:esearch.backend)
  let request = esearch#backend#{opts.backend}#init(cmd)

  call opts.set_default('out', g:esearch.out)
  let out_params = extend(opts.require('backend', 'adapter', 'cwd', 'exp', 'out'), {
        \ 'bufname': s:outbufname(pattern),
        \ 'request': request,
        \})

  call esearch#out#{opts.out}#init(out_params)
endfu

fu! s:outbufname(pattern) abort
  let format = s:bufname_format()
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

" Results bufname format getter
fu! s:bufname_format() abort
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

" fu! esearch#log(...)
"   PP a:000
"   call getchar()
" endfu
