if exists('g:loaded_esearch')
  finish
endif
let g:loaded_esearch = '0.2.1'

if !hasmapto('<Plug>(esearch)') && !hasmapto('<Plug>(operator-esearch-prefill)') && get(get(g:, 'esearch', {}), 'default_mappings', 1)
  nmap <leader>ff <Plug>(esearch)
  map  <leader>f  <Plug>(operator-esearch-prefill)
endif

nnoremap <silent><Plug>(esearch) :<C-u>call esearch#init()<CR>
xmap             <Plug>(esearch) <Plug>(operator-esearch-prefill)

noremap <expr><silent><Plug>(operator-esearch-prefill) esearch#util#operator_expr('esearch#opfunc_prefill')
noremap <expr><silent><Plug>(operator-esearch-exec)    esearch#util#operator_expr('esearch#opfunc_exec')
