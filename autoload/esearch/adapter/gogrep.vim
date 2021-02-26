fu! esearch#adapter#gogrep#new() abort
  return copy(s:Gogrep)
endfu

let s:Gogrep = esearch#adapter#base#import()

let s:Gogrep.bin = 'gogrep'
let s:Gogrep.options = '-tests'
let s:Gogrep.mandatory_options = ''

call extend(s:Gogrep, {
      \ 'regex':   {},
      \ 'textobj': {},
      \ 'case':    {},
      \ 'before':  0,
      \ 'after':   0,
      \ 'parser':  'with_col',
      \ 'multi_pattern': 1,
      \ 'pattern_kinds': [
      \   {'icon': '-x', 'opt': '-x ', 'regex': 0},
      \   {'icon': '-g', 'opt': '-g ', 'regex': 0},
      \   {'icon': '-v', 'opt': '-v ', 'regex': 0},
      \   {'icon': '-a', 'opt': '-a ', 'regex': 0},
      \ ],
      \ 'context': {'hint': 'parent nodes', 'opt': '-p'},
      \})

fu! s:Gogrep.command(esearch) abort dict
  if empty(a:esearch.paths)
    let paths = self.pwd()
  else
    let paths = esearch#shell#join(a:esearch.paths)
  endif

  let context = ''
  if a:esearch.context > 0 | let context .= ' -p ' . a:esearch.context | endif

  return join([
        \ self.bin,
        \ self.mandatory_options,
        \ self.options,
        \ context,
        \ a:esearch.pattern.arg,
        \ paths,
        \], ' ')
endfu

fu! s:Gogrep.pwd() abort dict
  return './...'
endfu
