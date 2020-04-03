let g:esearch#util_testing#originals = {}

fu! esearch#util_testing#spy_echo() abort
  if has_key(g:esearch#util_testing#originals, 'echon')
    throw 'Vimrunner(esearch#util_testing#spy_echo): already setupped'
  endif

  let Messages = esearch#message#import()
  let g:esearch#util#echo_calls_history = ['']
  let g:esearch#util_testing#originals.echon = Messages.echo
  let Messages.echon = function('<SID>echon')
endfu

fu! esearch#util_testing#unspy_echo() abort
  if !has_key(g:esearch#util_testing#originals, 'echo')
    throw 'Vimrunner(esearch#util_testing#spy_echo): spy is not setupped'
  endif

  let Messages = esearch#message#import()
  let Messages.echon = g:esearch#util_testing#originals.echon
  unlet g:esearch#util#echo_calls_history g:esearch#util_testing#originals.echon
endfu

fu! s:echon(color, string) abort
  let parts = split(a:string, "\n")
  if !empty(parts)
    let g:esearch#util#echo_calls_history[-1] .= parts[0]
    let g:esearch#util#echo_calls_history += parts[1:]
  elseif a:string =~# "\n"
    " split() function side effect
    let g:esearch#util#echo_calls_history += repeat([''], strchars(a:string))
  endif
  echon a:string
endfu
