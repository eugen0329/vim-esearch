fu! esearch#debounce#new(callback, wait, ...) abort
  return s:Trailing.new(a:callback, a:wait, a:000)
endfu

let s:Trailing = {'_timer': -1}

fu s:Trailing.new(callback, wait, ...) abort dict
  let instance = copy(self)
  let instance._wait     = a:wait
  " Wrapping into a list prevents from unbinding self. The same old story as
  " with js this.*.
  let instance._callback = [a:callback]

  return instance
endfu

fu! s:Trailing.apply(...) abort dict
  if self._timer >= 0
    call timer_stop(self._timer)
  endif

  " A separate variable is required, as otherwise closure won't work
  let args = a:000
  let self._timer = timer_start(self._wait, {_ -> call(self._callback[0], args) })
endfu

" TODO investigate which one is faster and probably deprecate
fu! esearch#debounce#_trailing(callback, wait, timer) abort
  if a:timer >= 0
    call timer_stop(a:timer)
  endif
  return timer_start(a:wait, a:callback)
endfu

" deprecated
let s:Trailing.invoke = s:Trailing.apply
fu! esearch#debounce#trailing(callback, wait) abort
  return esearch#debounce#new(a:callback, a:wait)
endfu
