let g:esearch#util_testing#originals = {}

fu! esearch#util_testing#spy_echo() abort
  if has_key(g:esearch#util_testing#originals, 'echo')
    throw 'Vimrunner(esearch#util_testing#spy_echo): already setupped'
  endif

  let g:esearch#util#echo_calls_history = []
  let g:esearch#util_testing#originals.echo = g:esearch#util#mockable.echo
  let g:esearch#util#mockable.echo = function('esearch#util_testing#echo_spyed')
endfu

fu! esearch#util_testing#unspy_echo() abort
  if !has_key(g:esearch#util_testing#originals, 'echo')
    throw 'Vimrunner(esearch#util_testing#spy_echo): spy is not setupped'
  endif

  let g:esearch#util#mockable.echo = g:esearch#util_testing#originals.echo
  unlet g:esearch#util#echo_calls_history g:esearch#util_testing#originals.echo
endfu

fu! esearch#util_testing#echo_spyed(string) abort
  call add(g:esearch#util#echo_calls_history, a:string)
  echo a:string
endfu
