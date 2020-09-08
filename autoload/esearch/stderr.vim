let s:String  = vital#esearch#import('Data.String')

" Handle stderr from backends

fu! esearch#stderr#append(esearch, errors) abort
  let a:esearch.request.errors += a:errors
  call esearch#stderr#incremental(a:esearch.adapter, a:errors) 
endfu

fu! esearch#stderr#incremental(adapter, errors) abort
  for message in a:errors
    call esearch#util#warn(a:adapter . ': ' . message)
  endfor
endfu

fu! esearch#stderr#finish(esearch) abort
  let errors = a:esearch.request.errors
  if empty(errors)
    let message = printf('%s returned status %d. No STDERR was provided',
          \ a:esearch.adapter,
          \ a:esearch.request.status,
          \ )
    call esearch#util#warn(message)
  endif
endfu
