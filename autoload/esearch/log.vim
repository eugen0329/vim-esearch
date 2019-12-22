fu! esearch#log#debug(msg, file) abort
  call system('echo "[DEBUG] " '.shellescape(a:msg).' >> '.shellescape(a:file))
endfu
