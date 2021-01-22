if exists('g:loaded_esearch')
  finish
endif
let g:loaded_esearch = '0.4.6'

if !hasmapto('<plug>(esearch)') && !hasmapto('<plug>(operator-esearch-prefill)') && get(get(g:, 'esearch', {}), 'default_mappings', 1)
  nmap <leader>ff <plug>(esearch)
  map  <leader>f  <plug>(operator-esearch-prefill)
endif

nnoremap <silent><plug>(esearch) :<c-u>call esearch#init({'remember': 1})<cr>
xmap             <plug>(esearch) <plug>(operator-esearch-prefill)

noremap <expr><silent><plug>(operator-esearch-prefill) esearch#prefill({'remember': 1})
noremap <expr><silent><plug>(operator-esearch-exec)    esearch#exec({'remember': 1})
