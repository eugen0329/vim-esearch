if !g:esearch#has#lua
  finish
endif

fu! esearch#adapter#parse#lua#funcref() abort
  return function('esearch#adapter#parse#lua#parse')
endfu

if g:esearch#has#nvim_lua
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    return luaeval('{esearch.parse.lines(_A[1])}', [a:data[a:from : a:to]])
  endfu
else
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    return luaeval('{esearch.parse.lines(_A[0])}', [a:data[a:from : a:to]])
  endfu
endif
