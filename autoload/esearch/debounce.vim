fu! esearch#debounce#trailing(callback, wait, timer) abort
  " TODO investigate how to make it work like a decorator
  if a:timer >= 0
    call timer_stop(a:timer)
  endif
  return timer_start(a:wait, a:callback)
endfu
