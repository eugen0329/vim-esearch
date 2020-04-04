fu! esearch#adapter#base#import() abort
  return copy(s:Base)
endfu

let s:Base = {
      \ 'bin': 'NotImplemented',
      \ 'options': 'NotImplemented',
      \ 'mandatory_options': 'NotImplemented'}

fu! s:Base.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.textobj[a:esearch.textobj].option
  let w = self.spec.case[a:esearch.case].option

  if empty(a:esearch.paths)
    let joined_paths = '.'
  else
    let joined_paths = esearch#shell#fnamesescape_and_join(a:esearch.paths, a:esearch.metadata)
  endif

  let context = ''
  if a:esearch.after > 0   | let context .= ' -A ' . a:esearch.after   | endif
  if a:esearch.before > 0  | let context .= ' -B ' . a:esearch.before  | endif
  if a:esearch.context > 0 | let context .= ' -C ' . a:esearch.context | endif

  return join([self.bin, r, c, w, self.mandatory_options, self.options, context], ' ')
        \ . ' -- ' .  a:escape(a:pattern) . ' ' . joined_paths
endfu

fu! s:Base.is_success(request) abort
  throw 'NotImplemented'
endfu
