fu! esearch#cache#expiring#new(opts) abort
  return s:Expiring.new(a:opts)
endfu

let s:Expiring = {}

fu! s:Expiring.new(opts) abort dict
  let instance = copy(self)
  let instance.max_age = a:opts.max_age
  let instance.size    = a:opts.size
  let instance.ages    = {}
  let instance.data    = {}

  return instance
endfu

fu! s:Expiring.has(key) abort dict
  return localtime() - get(self.ages, a:key) < self.max_age
endfu

fu! s:Expiring.get(key) abort dict
  if !self.has(a:key)
    return
  endif

  return self.data[a:key]
endfu

fu! s:Expiring.set(key, value) abort dict
  let self.data[a:key] = a:value
  let self.ages[a:key] = localtime()

  if len(self.data) >= self.size
    call self.evict()
  endif
endfu

" Random strategy that keeps 25% of data. Should be enough for now to prevent
" bloats
fu! s:Expiring.evict() abort dict
  for key in keys(self.ages)[ : len(self.ages) / 4]
    call self.remove(key)
  endfor
endfu

fu! s:Expiring.remove(key) abort dict
  call remove(self.data, a:key)
  call remove(self.ages, a:key)
endfu
