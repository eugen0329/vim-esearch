" TODO investigate what is faster
"
fu! esearch#debounce#_trailing(callback, wait, timer) abort
  if a:timer >= 0
    call timer_stop(a:timer)
  endif
  return timer_start(a:wait, a:callback)
endfu

fu! esearch#debounce#trailing(callback, wait) abort
  return {
        \ '_callback': a:callback,
        \ '_timer':    -1,
        \ '_wait':     a:wait,
        \ 'invoke':    function('<SID>invoke_trailing'),
        \ }
endfu

fu! s:invoke_trailing(...) abort dict
  if self._timer >= 0
    call timer_stop(self._timer)
  endif

  let self._timer = timer_start(self._wait, {_ -> call(self._callback, a:000) })
endfu
