fu! esearch#adapter#parse#lua#import() abort
  return function('esearch#adapter#parse#lua#parse')
endfu

if g:esearch#has#nvim_lua
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    return luaeval('{esearch.parse(_A[1], _A[2])}', [a:data[a:from : a:to], self._adapter.parser])
  endfu
else
  fu! esearch#adapter#parse#lua#parse(data, from, to) abort dict
    let [parsed, lines_delta, errors] =
          \ luaeval('vim.list({esearch.parse(_A.d, _A.p)})',
          \         {'d': a:data[a:from : a:to], 'p': self._adapter.parser})
    return [parsed, float2nr(lines_delta), errors]
  endfu
endif
