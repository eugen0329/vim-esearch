let s:Vital    = vital#esearch#new()
let s:Message  = s:Vital.import('Vim.Message')
let s:Filepath  = s:Vital.import('System.Filepath')

let g:cache = {}
let g:inverted_cache = {}

let g:extras = {
      \ '\.h$':    'c',
      \ '\.sh$':   'sh',
      \ '\.bash$': 'sh',
      \ '\.c$':    'c',
      \ '\.cpp$':  'cpp',
      \ '\.r$':    get(g:, 'filetype_r', 'r'),
      \ '\.sql$':  get(g:, 'filetype_r', 'sql'),
      \ '\.tex$':  'tex',
      \ '\.xml$':  'xml',
      \ '\.asm$':  'asm',
      \ '\.m$':    get(g:, 'filetype_m', 'objc'),
      \ '\.pl$':   get(g:, 'filetype_pl', 'perl'),
      \ }

let s:setf_commands = ['setfiletype', 'setf']

fu! esearch#ftdetect#slow(filename) abort
  let fast = esearch#ftdetect#fast(a:filename)

  if fast isnot 0
    return fast
  endif

  for [filetype, patterns] in items(g:cache)
    for pattern in patterns
      if a:filename =~# pattern
        return filetype
      endif
    endfor
  endfor

  return 0
endfu

fu! esearch#ftdetect#fast(filename) abort
  if exists('g:ft_ignore_pat') &&  a:filename =~# g:ft_ignore_pat
    return 0
  endif

  if empty(g:cache)
    call s:make_cache()
  endif

  let basename = s:Filepath.basename(a:filename)
  if has_key(g:inverted_cache, basename)
    return g:inverted_cache[basename]
  endif

  let basename_pattern = '^' . basename . '$'
  if has_key(g:inverted_cache, basename_pattern)
    return g:inverted_cache[basename_pattern]
  endif

  let extension_pattern = '\.'.fnamemodify(basename, ':e') . '$'
  if has_key(g:inverted_cache, extension_pattern)
    return g:inverted_cache[extension_pattern]
  endif

  if has_key(g:extras, extension_pattern)
    return g:extras[extension_pattern]
  endif

  return 0
endfu

fu! s:make_cache() abort
  let lines = split(s:Message.capture('autocmd filetypedetect'), "\n")

  let i = 0
  while i < len(lines)
    let parts = split(lines[i], '\s\+')

    if len(parts) == 1
      let i +=1
      let parts += split(lines[i], '\s\+')
    endif

    let pattern = glob2regpat(parts[0])

    if index(s:setf_commands, parts[1]) >= 0
      let filetype = parts[2]
    elseif parts[1] == 'call' && parts[2] =~# 'dist#ft#FT\l'
      let filetype = matchstr(parts[2], 'dist#ft#FT\zs\w\+\ze('  )
    elseif parts[1] == 'call' && parts[2] =~# '^\%(s:StarSetf\|s:setf\)('
      let filetype = matchstr(parts[2], '\%(s:StarSetf\|s:setf\)([''"]\zs\w\+\ze[''"])'  )
    else
      let i += 1
      continue
    endif

    if !has_key(g:cache, filetype)
      let g:cache[filetype] = []
    endif

    let g:inverted_cache[pattern] = filetype
    call add(g:cache[filetype], pattern)

    let i += 1
  endwhile
endfu

echo esearch#ftdetect#fast('main.js')
echo esearch#ftdetect#fast('main.jsx')
echo esearch#ftdetect#fast('main.c')
echo esearch#ftdetect#fast('main.h')
echo esearch#ftdetect#fast('main.cpp')
echo esearch#ftdetect#fast('main.hpp')
echo esearch#ftdetect#fast('main.h')
echo esearch#ftdetect#fast('main.r')
echo esearch#ftdetect#fast('main.hs')
echo esearch#ftdetect#fast('main.mof')
echo esearch#ftdetect#fast('main.vhdl')
echo esearch#ftdetect#slow('main.vhdl_1')
echo esearch#ftdetect#fast('Gemfile')
echo esearch#ftdetect#slow('Makefile')
echo esearch#ftdetect#slow('pom.xml')
echo esearch#ftdetect#slow('package.json')
echo esearch#ftdetect#slow('locales.yaml')
echo esearch#ftdetect#slow('index.html')
echo esearch#ftdetect#slow('locales.yml')
echo esearch#ftdetect#slow('script.bash')
echo esearch#ftdetect#slow('script.sh')
echo esearch#ftdetect#slow('main.m')
