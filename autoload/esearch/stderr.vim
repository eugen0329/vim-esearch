let s:Message = esearch#message#import()
let s:String  = vital#esearch#import('Data.String')

" Handle stderr from backends

fu! esearch#stderr#incremental(adapter, errors) abort
  let prefix = a:adapter . ': '

  for error in a:errors
    redraw
    call s:Message.echomsg('ErrorMsg',  prefix . error)
  endfor
endfu

fu! esearch#stderr#finish(esearch) abort
  let errors = a:esearch.request.errors

  if len(errors) > 1
    let message = printf('%s returned status %d. Last error: %s',
          \ a:esearch.adapter,
          \ a:esearch.request.status,
          \ s:String.dstring(errors[-1])
          \ )
    let message .= '. Run :messages to view the other ' . len(errors) . '.'
  elseif len(errors) == 1
    let message = printf('%s returned status %d: %s',
          \ a:esearch.adapter,
          \ a:esearch.request.status,
          \ s:String.dstring(errors[-1])
          \ )
  else
    let message = printf('%s returned status %d. No STDERR was provided',
          \ a:esearch.adapter,
          \ a:esearch.request.status,
          \ )
  endif
  redraw
  call s:Message.echomsg('ErrorMsg', message)
endfu
