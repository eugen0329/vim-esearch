if !exists('g:esearch#log#output')
  let g:esearch#log#output = '/tmp/esearch.log'
endif

fu! esearch#log#debug(...) abort
  if g:esearch#env is 0
    " ignore if accidentially called in production
    return
  endif

  if g:esearch#log#output is 1 " to resemble posix STDOUT_FILENO
    echo a:000
  else
    let items = join(map(deepcopy(a:000), 'string(v:val)'), ', ')
    call writefile(['[DEBUG] [' . items . ']'], g:esearch#log#output, 'a')
  endif
endfu
