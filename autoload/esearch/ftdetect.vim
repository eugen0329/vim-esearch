let s:Message  = vital#esearch#import('Vim.Message')
let s:Filepath = vital#esearch#import('System.Filepath')
let s:Promise  = vital#esearch#import('Async.Promise')
let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

let g:esearch#ftdetect#pattern2ft = {}
let s:prewarm = s:null
let s:setfiletype = ['setfiletype', 'setf']

" TODO consider to define either syntax file which highlights for strings,
" comments and keywords set for both languages with extension collisions (like
" matlab and objc for *.m)
if !exists('g:esearch_ftdetect_patterns')
  let g:esearch_ftdetect_patterns = {
        \ '\.sh$':     'sh',
        \ '\.bash$':   'sh',
        \ '\.bats$':   'sh',
        \ '\.c$':      'c',
        \ '\.h$':      'c',
        \ '\.cc$':     'cpp',
        \ '\.cpp$':    'cpp',
        \ '\.coffee$': 'coffee',
        \ '\.ts$':     'typescript',
        \ '\.tsx$':    'typescriptreact',
        \ '\.jsx$':    'javascriptreact',
        \ '\.r$':      get(g:, 'filetype_r', 'r'),
        \ '\.sql$':    get(g:, 'filetype_r', 'sql'),
        \ '\.tex$':    'tex',
        \ '\.xml$':    'xml',
        \ '\.html$':   'html',
        \ '\.asm$':    'asm',
        \ '\.toml$':   'toml',
        \ '\.tf$':     'hcl',
        \ '\.tfvars$': 'hcl',
        \ '\.hcl$':    'hcl',
        \ '\.m$':      get(g:, 'filetype_m', 'objc'),
        \ '\.pl$':     get(g:, 'filetype_pl', 'perl'),
        \ }
endif

fu! esearch#ftdetect#complete(filename) abort
  let filetype = esearch#ftdetect#fast(a:filename)
  if filetype isnot# s:null | return filetype | endif

  for [pattern, filetype] in items(g:esearch#ftdetect#pattern2ft)
    if a:filename =~# pattern
      return filetype
    endif
  endfor

  return s:null
endfu

fu! esearch#ftdetect#fast(filename) abort
  if exists('g:ft_ignore_pat') &&  a:filename =~# g:ft_ignore_pat
    return s:null
  endif

  if empty(g:esearch#ftdetect#pattern2ft) && !s:make_cache()
    return ''
  endif

  let basename = s:Filepath.basename(a:filename)
  let extension_pattern = '\.'.fnamemodify(basename, ':e') . '$'

  if has_key(g:esearch_ftdetect_patterns, extension_pattern)
    return g:esearch_ftdetect_patterns[extension_pattern]

  endif

  let basename_pattern = '^' . basename . '$'
  if has_key(g:esearch#ftdetect#pattern2ft, basename_pattern)
    return g:esearch#ftdetect#pattern2ft[basename_pattern]
  endif

  if has_key(g:esearch#ftdetect#pattern2ft, extension_pattern)
    return g:esearch#ftdetect#pattern2ft[extension_pattern]
  endif

  " is checked last as it's slower then other
  let opened_buffer_filetype = getbufvar(a:filename, '&filetype')
  if !empty(opened_buffer_filetype)
    return opened_buffer_filetype
  endif

  return s:null
endfu

fu! esearch#ftdetect#async_prewarm_cache() abort
  if empty(g:esearch#ftdetect#pattern2ft) && s:Promise.is_available()
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

    if index(s:setfiletype, definitions[1]) >= 0
      " Plain setfiletype
      let filetype = definitions[2]
    elseif definitions[1] ==# 'call' && definitions[2] =~# '^s:\%(StarSetf\|setf\)('
      " Filetypes specifying using methods with additional check for
      " g:ft_ignore_pat inside. Can be safely grabbed as the required checks are
      " already provided.
      let filetype = matchstr(definitions[2], 's:\%(StarSetf\|setf\)([''"]\zs\w\+\ze[''"])'  )
    else
      " If-elses or method calls to run against files content. Skip
      let definitions = []
      continue
    endif

    let g:esearch#ftdetect#pattern2ft[glob2regpat(definitions[0])] = filetype

    let definitions = []
  endfor

  return s:true
endfu

fu! s:make_cache() abort
  if s:Promise.is_available() && s:Promise.is_promise(s:prewarm)
    let [result, error] = s:Promise.wait(s:prewarm, { 'timeout': 1000 })

    if s:failed_with(error, s:Promise.TimeoutError)
      return s:false
    elseif error isnot# s:null
      echoerr 'Failed: ' . string(error)
    else
      let s:prewarm = s:null
    endif
  else
    call s:blocking_make_cache()
  endif

  return s:true
endfu

fu! s:failed_with(reason, error) abort
  return type(a:reason) == type(a:error) && a:reason ==# a:error
endfu
