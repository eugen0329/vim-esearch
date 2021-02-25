fu! esearch#glob#new(adapter, str) abort
  if !a:adapter.glob | return 0 | endif
  return s:GlobSet.new(a:adapter.glob_kinds, a:str)
endfu

let s:GlobSet = {}

fu! s:GlobSet.new(kinds, str) abort dict
  let new = copy(self)
  let new.kinds = esearch#util#cycle(a:kinds)
  let new.globs = esearch#util#stack([s:Glob.from_kind(new.kinds.next(), a:str)])
  let new.list = new.globs.list
  return new
endfu

" TODO
fu! s:GlobSet.arg() abort
  echomsg self.list
  return join(map(self.list, 'shellescape(v:val.str)'), ' ')
endfu

fu! s:GlobSet.replace(str) abort dict
  return self.globs.replace(extend(copy(self.globs.top()), {'str': a:str}))
endfu

fu! s:GlobSet.push(str) abort dict
  return self.globs.push(s:Glob.from_kind(self.kinds.next(), a:str))
endfu

fu! s:GlobSet.try_pop() abort dict
  if self.globs.len() < 2 | return | endif
  return self.globs.pop()
endfu

fu! s:GlobSet.next() abort dict
  return self.globs.replace(s:Glob.from_kind(self.kinds.next(), self.peek().str))
endfu

fu! s:GlobSet.peek() abort dict
  return self.globs.top()
endfu

let s:Glob = {}

fu! s:Glob.new(icon, opt, str) abort dict
  return extend(copy(self), {'icon': a:icon, 'opt': a:opt, 'str': a:str})
endfu

fu! s:Glob.from_kind(kind, str) abort
  return s:Glob.new(a:kind.icon, a:kind.opt, a:str)
endfu

fu! s:Glob.convert(_esearch) abort dict
  let self.arg = shellescape(self.str)
  return self
endfu
