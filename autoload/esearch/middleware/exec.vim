fu! esearch#middleware#exec#apply(esearch) abort
  if a:esearch.live_update && !a:esearch.force_exec | return a:esearch | endif

  let command = a:esearch._adapter.command(a:esearch)
  let a:esearch.request = esearch#backend#{a:esearch.backend}#init(
        \ a:esearch.cwd, a:esearch.adapter, command)
  call esearch#backend#{a:esearch.backend}#exec(a:esearch.request)

  return a:esearch
endfu
