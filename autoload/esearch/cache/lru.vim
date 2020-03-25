let s:OrderedSet = vital#esearch#import('Data.OrderedSet')

fu! esearch#cache#lru#new(size) abort
  return s:LRU.new(a:size)
endfu

let s:LRU = {}

fu! s:LRU.new(size, ...) abort dict
  let instance = copy(self)
  let instance.size = a:size
  let instance.queue = s:OrderedSet.new()
  let instance.data = {}

  return instance
endfu

fu! s:LRU.has(key) abort dict
  return self.queue.has(a:key)
endfu

fu! s:LRU.get(key) abort dict
  call self.queue.remove(a:key)
  call self.queue.unshift(a:key)

  return self.data[string(a:key)]
endfu

fu! s:LRU.set(key, value) abort dict
  if !self.has(a:key) && self.queue.size() >= self.size
    call self.remove(self.queue.to_list()[-1])
  endif

  call self.queue.unshift(a:key)
  let self.data[string(a:key)] = a:value
endfu

fu! s:LRU.remove(key) abort dict
  call self.queue.remove(a:key)
  let value = remove(self.data, string(a:key))

  " Trigger the destructor if it's available
  if type(value) ==# type({}) && has_key(value, 'remove')
    call value.remove()
  endif
endfu
