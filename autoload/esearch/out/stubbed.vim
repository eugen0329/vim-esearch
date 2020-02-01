fu! esearch#out#stubbed#init(out_params)
  if !exists('g:stubbed_output_args_history')
    let g:stubbed_output_args_history = []
  endif
  call add(g:stubbed_output_args_history, a:out_params)
endfu
