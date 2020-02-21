fu! esearch#log#debug(...) abort
  if g:esearch#env == 'dev'
    echo a:000
  elseif g:esearch#env == 'test'
    call writefile(['[DEBUG]' . join(esearch#util#flatten(a:000) '; ')], '/tmp/esearch.log', 'a')
  else
    " ignore if accidentially called in production
  endif
endfu
