let s:Log = copy(vital#esearch#import('Vim.Message'))

fu! esearch#log#import() abort
  return s:Log
endfu

fu! s:Log.info(msg) abort dict
  for m in split(a:msg, "\n")
    echomsg m
  endfor
endfu

fu! s:Log.echon(hl, msg) abort dict
  execute 'echohl' a:hl
  try
    echon a:msg
  finally
    echohl None
  endtry
endfu

fu! esearch#log#echo(msg, ...) abort
  call s:Log.echo(get(a:, 1, 'NONE'), a:msg)
endfu

fu! esearch#log#echomsg(msg, hl) abort
  call s:Log.echomsg(get(a:, 1, 'NONE'), a:msg)
endfu
