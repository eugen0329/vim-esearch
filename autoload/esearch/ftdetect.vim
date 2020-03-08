let s:Vital    = vital#esearch#new()
let s:Message  = s:Vital.import('Vim.Message')
let s:Filepath = s:Vital.import('System.Filepath')
let s:List     = s:Vital.import('Data.List')
let s:Promise  = s:Vital.import('Async.Promise')

let s:pattern_to_filetype = {}
let s:null = 0
let s:prewarm = s:null
let s:setfiletype = ['setfiletype', 'setf']

" TODO consider to define either syntax file which highlights for strings,
" comments and keywords set for both languages with extension collisions (like
" matlab and objc for *.m)
if !exists('g:esearch_ftdetect_patterns')
  let g:esearch_ftdetect_patterns = {
        \ '\.sh$':   'sh',
        \ '\.bash$': 'sh',
        \ '\.bats$': 'sh',
        \ '\.c$':    'c',
        \ '\.h$':    'c',
        \ '\.cpp$':  'cpp',
        \ '\.tsx$':  'typescript',
        \ '\.ts$':   'typescript',
        \ '\.jsx$':  'javascriptreact',
        \ '\.r$':    get(g:, 'filetype_r', 'r'),
        \ '\.sql$':  get(g:, 'filetype_r', 'sql'),
        \ '\.tex$':  'tex',
        \ '\.xml$':  'xml',
        \ '\.html$': 'html',
        \ '\.asm$':  'asm',
        \ '\.toml$': 'toml',
        \ '\.m$':    get(g:, 'filetype_m', 'objc'),
        \ '\.pl$':   get(g:, 'filetype_pl', 'perl'),
        \ }
endif

fu! esearch#ftdetect#slow(filename) abort
  let filetype = esearch#ftdetect#fast(a:filename)
  if filetype isnot# 0 | return filetype | endif

  for [pattern, filetype] in items(s:pattern_to_filetype)
    if a:filename =~# pattern
      return filetype
    endif
  endfor

  return 0
endfu

fu! esearch#ftdetect#fast(filename) abort
  if exists('g:ft_ignore_pat') &&  a:filename =~# g:ft_ignore_pat
    return 0
  endif

  if empty(s:pattern_to_filetype) && !s:make_cache()
    return ''
  endif

  let basename = s:Filepath.basename(a:filename)
  let extension_pattern = '\.'.fnamemodify(basename, ':e') . '$'

  if has_key(g:esearch_ftdetect_patterns, extension_pattern)
    return g:esearch_ftdetect_patterns[extension_pattern]

  endif

  let basename_pattern = '^' . basename . '$'
  if has_key(s:pattern_to_filetype, basename_pattern)
    return s:pattern_to_filetype[basename_pattern]
  endif

  if has_key(s:pattern_to_filetype, extension_pattern)
    return s:pattern_to_filetype[extension_pattern]
  endif

  " is checked last as it's slower then other
  let opened_buffer_filetype = getbufvar(a:filename, '&filetype')
  if !empty(opened_buffer_filetype)
    return opened_buffer_filetype
  endif

  return 0
endfu

fu! esearch#ftdetect#async_prewarm_cache() abort
  if s:Promise.is_available()
    " TODO split captured command lines by chunks and process during multiple calls
    " of blocking_make_cache, otherwise this call doesn't make sense
    let s:prewarm = s:Promise
          \.new({resolve -> timer_start(0, resolve)})
          \.then({-> s:blocking_make_cache()})
          \.catch({reason -> execute('echoerr reason')})
  endif
endfu

fu! s:blocking_make_cache() abort
  let lines = split(s:Message.capture('autocmd filetypedetect'), "\n")

  let definitions = []
  for line in lines
    if empty(definitions)
      let definitions = split(line, '\s\+')
      if len(definitions) < 2
        continue
      endif
    elseif len(definitions) < 2
      " Automcommand spans two lines (long wildcard is on the first, commands
      " are on the second). Grab the commands.
      let definitions += split(line, '\s\+')
    endif

    if s:List.has(s:setfiletype, definitions[1])
      " Plain setfiletype
      let filetype = definitions[2]
    elseif definitions[1] ==# 'call' && definitions[2] =~# '^s:\%(StarSetf\|setf\)('
      " Filetypes set with additional check for g:ft_ignore_pat. Can be safely
      " grabbed as the required checks are already provided
      let filetype = matchstr(definitions[2], 's:\%(StarSetf\|setf\)([''"]\zs\w\+\ze[''"])'  )
    else
      " If-elses or method calls to run against files content. Skip
      let definitions = []
      continue
    endif

    let s:pattern_to_filetype[glob2regpat(definitions[0])] = filetype

    let definitions = []
  endfor

  return 1
endfu

fu! s:make_cache() abort
  if s:Promise.is_available() && s:Promise.is_promise(s:prewarm)
    let [result, error] = s:Promise.wait(s:prewarm, { 'timeout': 1000 })

    if s:failed_with(error, s:Promise.TimeoutError)
      return 0
    elseif error isnot# v:null
      echoerr 'Failed: ' . string(error)
    else
      let s:prewarm = s:null
    endif
  else
    call s:blocking_make_cache()
  endif

  return 1
endfu

fu! s:failed_with(reason, error) abort
  return type(a:reason) == type(a:error) && a:reason ==# a:error
endfu
