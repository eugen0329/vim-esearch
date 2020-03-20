if !exists('g:esearch#debug#log_output')
  let g:esearch#debug#output = '/tmp/esearch.log'
endif

fu! esearch#debug#log(...) abort
  if g:esearch#env is# 0
    " ignore if accidentially called in production
    return
  endif

  if g:esearch#debug#log_output is# 1 " to resemble posix STDOUT_FILENO
    echo a:000
  else
    let items = join(map(deepcopy(a:000), 'string(v:val)'), ', ')
    call writefile(['[DEBUG] [' . items . ']'], g:esearch#debug#log_output, 'a')
  endif
endfu
