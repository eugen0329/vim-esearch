fu! esearch#log#debug(msg, file) abort
  call writefile(['[DEBUG]'.join(esearch#util#flatten([a:msg]), '; ')], a:file, 'a')
endfu
