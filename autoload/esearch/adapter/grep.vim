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
      \   'literal':  {'icon': '',  'opt': '-F'},
      \   'basic':    {'icon': 'G', 'opt': '-G'},
      \   'extended': {'icon': 'E', 'opt': '-E'},
      \   'pcre':     {'icon': 'P', 'opt': '-P'},
      \ },
      \ 'bool2textobj': ['none', 'word'],
      \ 'textobj': {
      \   'none':     {'icon': '',  'opt': ''},
      \   'word':     {'icon': 'w', 'opt': '-w'},
      \   'line':     {'icon': 'l', 'opt': '-x'},
      \ },
      \ 'bool2case': ['ignore', 'sensitive'],
      \ 'case': {
      \   'ignore':    {'icon':  '', 'opt': '-i'},
      \   'sensitive': {'icon': 's', 'opt': ''},
      \ },
      \ 'multi_pattern': 1,
      \ 'pattern_kinds': [{'icon': '', 'opt': '-e ', 'regex': 1}],
      \})


" TODO globs
" fu! s:Rg._command(esearch, glob_or_pattern) abort dict
fu! s:Grep.command(esearch) abort dict
  let regex = self.regex[a:esearch.regex].opt
  let case = self.textobj[a:esearch.textobj].opt
  let textobj = self.case[a:esearch.case].opt

  if empty(a:esearch.paths)
    let paths = self.pwd()
  else
    let paths = esearch#shell#join(a:esearch.paths)
  endif

  let context = ''
  if a:esearch.after > 0   | let context .= ' -A ' . a:esearch.after   | endif
  if a:esearch.before > 0  | let context .= ' -B ' . a:esearch.before  | endif
  if a:esearch.context > 0 | let context .= ' -C ' . a:esearch.context | endif

  return join([
        \ self.bin,
        \ regex,
        \ case,
        \ textobj,
        \ self.mandatory_options,
        \ self.options,
        \ context,
        \ a:esearch.pattern.arg,
        \ '--',
        \ paths,
        \], ' ')
endfu


fu! s:Grep.is_success(request) abort
  " 0 if a line is match, 1 if no lines matched, > 1 are for errors
  return a:request.status == 0 || a:request.status == 1
endfu

fu! s:Grep.pwd() abort dict
  return '.'
endfu
