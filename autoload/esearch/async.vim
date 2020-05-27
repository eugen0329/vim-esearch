fu! esearch#async#debounce(callback, wait, ...) abort
  return s:Trailing.new(a:callback, a:wait, a:000)
endfu

let s:Trailing = {'t': -1}

fu! s:Trailing.new(callback, wait, ...) abort dict
  let instance   = copy(self)
  let instance.w = a:wait
  " Wrapping into a list prevents from unbinding self. The same old story as
  " with js this.*.
  let instance.c = [a:callback]

  return instance
endfu

fu! s:Trailing.cancel(...) abort dict
  call timer_stop(self.t)
endfu

fu! s:Trailing.apply(...) abort dict
  call timer_stop(self.t)
  let a = a:000
  let self.t = timer_start(self.w, {_ -> call(self.c[0], a) })
endfu
