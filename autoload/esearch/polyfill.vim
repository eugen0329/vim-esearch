if g:esearch#has#vim8_types
  let s:true     = v:true
  let s:false    = v:false
  let s:null     = v:null
  let s:t_dict   = v:t_dict
  let s:t_float  = v:t_float
  let s:t_func   = v:t_func
  let s:t_list   = v:t_list
  let s:t_number = v:t_number
  let s:t_string = v:t_string
else
  let s:true     = 1
  let s:false    = 0
  let s:null     = 0
  let s:t_dict   = type({})
  let s:t_float  = type(1.0)
  let s:t_func   = type(function('tr'))
  let s:t_list   = type([])
  let s:t_number = type(1)
  let s:t_string = type('')
endif

fu! esearch#polyfill#definitions() abort
  return [
        \ s:true,
        \ s:false,
        \ s:null,
        \ s:t_dict,
        \ s:t_float,
        \ s:t_func,
        \ s:t_list,
        \ s:t_number,
        \ s:t_string,
        \]
endfu

fu! esearch#polyfill#undefined() abort
  return function('esearch#polyfill#undefined')
endfu
