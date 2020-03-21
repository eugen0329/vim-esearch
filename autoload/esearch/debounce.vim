" TODO investigate what is faster
"
fu! esearch#debounce#_trailing(callback, wait, timer) abort
  if a:timer >= 0
    call timer_stop(a:timer)
  endif
  return timer_start(a:wait, a:callback)
endfu

fu! esearch#debounce#trailing(callback, wait) abort
  " Wrapping into the list prevents from unbinding self. The same old story as
  " with js this.
  return {
        \ '_callback': [a:callback],
        \ '_timer':    -1,
        \ '_wait':     a:wait,
        \ 'invoke':    function('<SID>invoke_trailing'),
        \ }
endfu

fu! s:invoke_trailing(...) abort dict
  if self._timer >= 0
    call timer_stop(self._timer)
  endif

  " otherwise closure won't work
  let args = a:000
  let self._timer = timer_start(self._wait, {_ -> call(self._callback[0], args) })
endfu
