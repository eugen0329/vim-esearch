" Python-like utility functions for iteration

fu! esearch#itertools#count() abort
  return s:Count.new()
endfu

fu! esearch#itertools#cycle(list) abort
  return s:Cycle.new(a:list)
endfu

let s:Count = {'_value': 0}

fu! s:Count.new() abort dict
  return copy(self)
endfu

fu! s:Count.next() abort dict
  let self._value += 1
  return self._value - 1
endfu

let s:Cycle = {}

fu! s:Cycle.new(list) abort dict
  return extend(copy(self), {'list': a:list, 'i': 0})
endfu

fu! s:Cycle.next() abort dict
  let next = self.list[self.i]
  let self.i = self.i == len(self.list) - 1 ? 0 : self.i + 1
  return next
endfu
