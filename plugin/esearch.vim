if exists('g:loaded_esearch')
  finish
endif
let g:loaded_esearch = '0.1.0'

if !hasmapto('<Plug>(esearch)') && !hasmapto('<Plug>(esearch-operator)') && get(get(g:, 'esearch', {}), 'default_mappings', 1)
  nmap <leader>ff <Plug>(esearch)
  map  <leader>f  <Plug>(esearch-prefill)
endif

nnoremap       <silent><Plug>(esearch)         :<C-u>call esearch#init()<CR>
xmap                   <Plug>(esearch)         <Plug>(esearch-prefill)
noremap  <expr><silent><Plug>(esearch-prefill) esearch#util#operator_expr('esearch#opfunc_prefill')
noremap  <expr><silent><Plug>(esearch-exec)    esearch#util#operator_expr('esearch#opfunc_exec')
