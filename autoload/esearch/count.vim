fu! esearch#count#new() abort
  return s:Count.new()
endfu

let s:Count = {'_value': 0}

fu! s:Count.new() abort dict
  return copy(self)
endfu

fu! s:Count.next() abort dict
  let self._value += 1
  return self._value
endfu
