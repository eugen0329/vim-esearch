let s:Message = vital#esearch#import('Vim.Message')
let s:String  = vital#esearch#import('Data.String')

" Handle stderr from backends

fu! esearch#stderr#incremental(errors) abort
  let prefix = b:esearch.adapter . ': '

  for error in a:errors
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
    let message .= '. See :messages to view other ' . len(errors) . '.'
  elseif len(errors) == 1
    let message = printf('%s returned status %d: %s',
          \ a:esearch.adapter,
          \ a:esearch.request.status,
          \ s:String.dstring(errors[-1])
          \ )
  else
    let message = printf("%s returned status %d. No STDERR was provided",
          \ a:esearch.adapter,
          \ a:esearch.request.status,
          \ )
  endif

  call s:Message.echomsg('ErrorMsg', message)
endfu
