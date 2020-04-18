fu! esearch#adapter#base#import() abort
  return copy(s:Base)
endfu

let s:Base = {
      \ 'bin': 'NotImplemented',
      \ 'options': 'NotImplemented',
      \ 'mandatory_options': 'NotImplemented'}

fu! s:Base.command(esearch, pattern, escape) abort dict
  let regex = self.spec.regex[a:esearch.regex].option
  let case = self.spec.textobj[a:esearch.textobj].option
  let textobj = self.spec.case[a:esearch.case].option

  if empty(a:esearch.paths)
    let paths = self.pwd()
  else
    let paths = join(map(copy(a:esearch.paths), 'esearch#shell#escape(v:val)'), ' ')
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
        \ ' -- ',
        \ a:escape(a:pattern),
        \ paths,
        \], ' ')
endfu

fu! s:Base.pwd() abort dict
  " Some adapters require pwd to set explicitly (like grep) using '.'. For
  " others it cause unwanted './' prefix.
  return ''
endfu

" '' and '--' separators are outputted when context height options are given
fu! s:Base.outputs_separators(esearch) abort
  return a:esearch.context != 0 || a:esearch.before != 0 || a:esearch.after != 0
endfu

fu! s:Base.is_success(request) abort
  throw 'NotImplemented'
endfu
