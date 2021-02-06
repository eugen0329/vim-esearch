fu! esearch#adapter#grep#new() abort
  return copy(s:Grep)
endfu

let s:Grep = esearch#adapter#base#import()

if exists('g:esearch#adapter#grep#bin')
  call esearch#util#deprecate('g:esearch#adapter#grep#options. Please, use g:esearch.adapters.grep.bin')
  let s:Grep.bin = g:esearch#adapter#grep#bin
else
  let s:Grep.bin = 'grep'
endif
if exists('g:esearch#adapter#grep#options')
  call esearch#util#deprecate('g:esearch#adapter#grep#options. Please, use g:esearch.adapters.grep.options')
  let s:Grep.options = g:esearch#adapter#grep#options
else
  " -I: don't match binary files
  let s:Grep.options = '-I'
endif

" Short options are used as they are supported more often than long ones

" -n: output line numbers
" -R: recursive, follow symbolic links
" -H: Print the file name for each match.
" -x: Line regexp
let s:Grep.mandatory_options = '-H -R -n'
call extend(s:Grep, {
      \ 'bool2regex': ['literal', 'basic'],
      \ 'regex': {
      \   'literal':  {'icon': '',  'option': '-F'},
      \   'basic':    {'icon': 'G', 'option': '-G'},
      \   'extended': {'icon': 'E', 'option': '-E'},
      \   'pcre':     {'icon': 'P', 'option': '-P'},
      \ },
      \ 'bool2textobj': ['none', 'word'],
      \ 'textobj': {
      \   'none':     {'icon': '',  'option': ''},
      \   'word':     {'icon': 'w', 'option': '-w'},
      \   'line':     {'icon': 'l', 'option': '-x'},
      \ },
      \ 'bool2case': ['ignore', 'sensitive'],
      \ 'case': {
      \   'ignore':    {'icon':  '', 'option': '-i'},
      \   'sensitive': {'icon': 's', 'option': ''},
      \ }
      \})

fu! s:Grep.is_success(request) abort
  " 0 if a line is match, 1 if no lines matched, > 1 are for errors
  return a:request.status == 0 || a:request.status == 1
endfu

fu! s:Grep.pwd() abort dict
  return '.'
endfu
