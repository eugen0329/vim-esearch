let s:Message = copy(vital#esearch#import('Vim.Message'))

fu! esearch#log#import() abort
  return s:Message
endfu

fu! s:Message.echon(hl, msg) abort dict
  execute 'echohl' a:hl
  try
    echon a:msg
  finally
    echohl None
  endtry
endfu

fu! esearch#log#echo(hl, msg) abort
  call s:Message.echo(a:hl, a:msg)
endfu
