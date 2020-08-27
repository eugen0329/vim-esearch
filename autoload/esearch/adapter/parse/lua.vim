fu! esearch#adapter#parse#lua#funcref() abort
  return function('esearch#adapter#parse#lua#parse')
endfu

if g:esearch#has#nvim_lua
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    return luaeval('{esearch.parse.lines(_A)}', a:data[a:from : a:to])
  endfu
else
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    echomsg [a:data, a:from, a:to]
    let [parsed, separators_count] = luaeval('vim.list({esearch.parse.lines(_A)})', a:data[a:from : a:to])
    return [parsed, float2nr(separators_count)]
  endfu
endif
