let s:OrderedSet = vital#esearch#import('Data.OrderedSet')

fu! esearch#cache#lru#new(size) abort
  return s:LRU.new(a:size)
endfu

let s:LRU = {}

fu! s:LRU.new(size) abort dict
  let instance = copy(self)

  let instance.size = a:size
  let instance.queue = s:OrderedSet.new()
  let instance.storage = {}
  return instance
endfu

fu! s:LRU.has(key) abort dict
  let key = string(a:key)
  return self.queue.has(a:key)
endfu

fu! s:LRU.get(key) abort dict
  let key = string(a:key)

  if !self.queue.has(key)
    throw ''
  endif

  call self.queue.remove(key)
  call self.queue.unshift(key)

  return self.storage[key]
endfu

fu! s:LRU.set(key, value) abort dict
  let key = string(a:key)

  if !self.has(key) && self.queue.size() > self.size
    let last = self.queue.to_list()[-1]
    call self.queue.remove(last)
    unlet self.storage[last]
  endif

  call self.queue.unshift(key)
  let self.storage[key] = a:value
endfu
