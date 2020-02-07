let s:Vital    = vital#esearch#new()
let s:Message  = s:Vital.import('Vim.Message')
let s:Filepath = s:Vital.import('System.Filepath')
let s:List     = s:Vital.import('Data.List')

let s:pattern_to_filetype = {}
let s:setf_commands = ['setfiletype', 'setf']

" TODO consider to define either syntax file which highlights strings, comments
" and keywords set from both languages (like matlab and objc for *.m)
if !exists('g:esearch_ftdetect_patterns')
  let g:esearch_ftdetect_patterns = {
        \ '\.sh$':   'sh',
        \ '\.bash$': 'sh',
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
        \ '\.m$':    get(g:, 'filetype_m', 'objc'),
        \ '\.pl$':   get(g:, 'filetype_pl', 'perl'),
        \ }
endif

fu! esearch#ftdetect#slow(filename) abort
  let filetype = esearch#ftdetect#fast(a:filename)
  if filetype isnot 0 | return filetype | endif

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

  if empty(s:pattern_to_filetype)
    call s:make_cache()
  endif

  let basename = s:Filepath.basename(a:filename)
  let extension_pattern = '\.'.fnamemodify(basename, ':e') . '$'

  if has_key(g:esearch_ftdetect_patterns, extension_pattern)
    return g:esearch_ftdetect_patterns[extension_pattern]

  endif

  let opened_buffer_filetype = getbufvar(a:filename, '&filetype')
  if !empty(opened_buffer_filetype)
    return opened_buffer_filetype
  endif

  let basename_pattern = '^' . basename . '$'
  if has_key(s:pattern_to_filetype, basename_pattern)
    return s:pattern_to_filetype[basename_pattern]
  endif

  if has_key(s:pattern_to_filetype, extension_pattern)
    return s:pattern_to_filetype[extension_pattern]
  endif

  return 0
endfu

fu! s:make_cache() abort
  let lines = split(s:Message.capture('autocmd filetypedetect'), "\n")

  let definitions = []
  for line in lines
    if empty(definitions)
      let definitions = split(line, '\s\+')
      continue
    elseif len(definitions) == 1
      " Automcommand spans two lines (long wildcard is on the first, commands
      " are on the second). Grab the commands.
      let definitions += split(line, '\s\+')
    endif

    if s:List.has(s:setf_commands, definitions[1])
      " Plain setfiletype
      let filetype = definitions[2]
    elseif definitions[1] == 'call' && definitions[2] =~# '^s:\%(StarSetf\|setf\)('
      " Filetypes set with additional check for g:ft_ignore_pat. Can be safely
      " grabbed
      let filetype = matchstr(definitions[2], 's:\%(StarSetf\|setf\)([''"]\zs\w\+\ze[''"])'  )
    else
      " If-elses or method calls to run against files content. Skip
      let definitions = []
      continue
    endif

    let s:pattern_to_filetype[glob2regpat(definitions[0])] = filetype

    let definitions = []
  endfor
endfu
