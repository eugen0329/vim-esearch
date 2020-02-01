fu! esearch#out#stubbed#init(out_params) abort
  if !exists('g:esearch#out#stubbed#calls_history')
    let g:esearch#out#stubbed#calls_history = []
  endif
  call add(g:esearch#out#stubbed#calls_history, a:out_params)
endfu
