fu! esearch#middleware#exec#apply(esearch) abort
  let Escape = function('esearch#backend#'.a:esearch.backend.'#escape_cmd')
  let command = a:esearch.current_adapter.command(a:esearch, a:esearch.pattern.arg, Escape)
  let a:esearch.request = esearch#backend#{a:esearch.backend}#init(
        \ a:esearch.cwd, a:esearch.adapter, command)
  call esearch#backend#{a:esearch.backend}#exec(a:esearch.request)

  return a:esearch
endfu
