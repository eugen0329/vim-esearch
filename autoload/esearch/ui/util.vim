let g:esearch#ui#util#INF = float2nr(str2float('inf'))

fu! esearch#ui#util#cycle_mode(esearch, mode) abort
  let kinds = keys(a:esearch._adapter[a:mode])
  let a:esearch[a:mode] = kinds[(index(kinds, a:esearch[a:mode]) + 1) % len(kinds)]
  return a:esearch
endfu

fu! esearch#ui#util#c(cases, case, offset) abort
  let kinds = keys(a:cases)
  return kinds[(esearch#util#mod(index(kinds, a:case) + a:offset, len(kinds)))]
endfu

fu! esearch#ui#util#with_cmdpos(cmdline) abort
  let [text, cmdpos] = a:cmdline
  if cmdpos < 0 | let cmdpos += len(text) + 2 | endif
  if cmdpos > len(text) | return text | endif
  return text.repeat("\<left>", strchars(text) + 1 - strchars(strpart(text, 0, cmdpos)))
endfu
