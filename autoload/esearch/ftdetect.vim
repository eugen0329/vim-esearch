let s:Log  = esearch#log#import()
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
if !exists('g:esearch_ftdetect_re2filetype')
  let g:esearch_ftdetect_re2filetype = {
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
        \ '\.sql$':    get(g:, 'filetype_sql', 'sql'),
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

fu! esearch#ftdetect#slow(filename) abort
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
  let extension_re = '\.' . fnamemodify(basename, ':e') . '$'

  if has_key(g:esearch_ftdetect_re2filetype, extension_re)
    return g:esearch_ftdetect_re2filetype[extension_re]

  endif

  let basename_re = '^' . basename . '$'
  if has_key(g:esearch#ftdetect#pattern2ft, basename_re)
    return g:esearch#ftdetect#pattern2ft[basename_re]
  endif

  if has_key(g:esearch#ftdetect#pattern2ft, extension_re)
    return g:esearch#ftdetect#pattern2ft[extension_re]
  endif

  " is checked last as it's slower then others
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
  try
    let lines = split(s:Log.capture('autocmd filetypedetect'), "\n")
  catch /E216:/ " E216: No such group or event
    return 0
  endtry

  let tokens = []
  for line in lines
    if empty(tokens)
      let tokens = split(line, '\s\+')
      if len(tokens) < 2
        continue
      endif
    elseif len(tokens) < 2
      " Automcommand spans two lines (long wildcard is on the first, commands
      " are on the second). Grab the commands.
      let tokens += split(line, '\s\+')
    endif

    if index(s:setfiletype, tokens[1]) >= 0
      " Plain setfiletype
      let filetype = tokens[2]
    elseif tokens[1] ==# 'call' && tokens[2] =~# '^s:\%(StarSetf\|setf\)('
      " Filetypes specifying using methods with additional check for
      " g:ft_ignore_pat inside. Can be safely grabbed as the required checks are
      " already provided.
      let filetype = matchstr(tokens[2], 's:\%(StarSetf\|setf\)([''"]\zs\w\+\ze[''"])'  )
    else
      " If-elses or method calls to run against files content. Skip
      let tokens = []
      continue
    endif

    let g:esearch#ftdetect#pattern2ft[glob2regpat(tokens[0])] = filetype

    let tokens = []
  endfor

  return 1
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

  return 1
endfu

fu! s:failed_with(reason, error) abort
  return type(a:reason) == type(a:error) && a:reason ==# a:error
endfu
