if g:esearch#has#vim8_types
  let s:values = {
        \ 'true': v:true,
        \ 'false': v:false,
        \ 'null': v:null,
        \ 't_dict': v:t_dict,
        \ }
else
  let s:values = {
        \ 'true': 1,
        \ 'false': 0,
        \ 'null': 0,
        \ 't_dict': type({}),
        \ }
endif

fu! esearch#polyfill#extend(scope) abort
  call extend(a:scope, s:values, 'force')
endfu
