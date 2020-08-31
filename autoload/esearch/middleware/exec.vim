fu! esearch#middleware#exec#apply(esearch) abort
  let command = a:esearch.current_adapter.command(a:esearch)
  let a:esearch.request = esearch#backend#{a:esearch.backend}#init(
        \ a:esearch.cwd, a:esearch.adapter, command)
  call esearch#backend#{a:esearch.backend}#exec(a:esearch.request)

  return a:esearch
endfu
