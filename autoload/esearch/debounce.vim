fu esearch#debounce#trailing(callback, wait, timer) abort
  if a:timer >= 0
    call timer_stop(a:timer)
  endif
  return timer_start(a:wait, a:callback)
endfu
