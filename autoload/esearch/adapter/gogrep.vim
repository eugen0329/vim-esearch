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
      \ 'parser':  'withcol',
      \ 'patterns': [
      \   {'opt': '-x', 'regex': 0},
      \   {'opt': '-g', 'regex': 0},
      \   {'opt': '-v', 'regex': 0},
      \   {'opt': '-a', 'regex': 0},
      \],
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
        \ '-x',
        \ a:esearch.pattern.arg,
        \ paths,
        \], ' ')
endfu

let s:Gogrep.filetypes = ''

fu! s:Gogrep.pwd() abort dict
  return './...'
endfu

fu! s:Gogrep.filetypes2agogreps(filetypes) abort dict
  return ''
endfu

fu! s:Gogrep.is_success(request) abort
  return a:request.status == 0
endfu

