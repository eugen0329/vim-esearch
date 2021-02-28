let s:List = vital#esearch#import('Data.List')
let s:Log = esearch#log#import()

fu! esearch#ui#render#string(chunks) abort
  return join(map(copy(a:chunks), 'v:val[0]'), '')
endfu

fu! esearch#ui#render#echo(chunks) abort
  try
    for [text, hl] in a:chunks
      exe 'echohl' hl
      echon text
    endfor
  finally
    echohl None
  endtry
endfu

fu! esearch#ui#render#statusline_string(chunks) abort
  let result = ''
  let winwidth = winwidth(0) - 2
  let result_width = 0

  for [text, hl] in a:chunks
    let text = esearch#util#ellipsize_end(text, winwidth - result_width, '..')
    let result_width += strdisplaywidth(text)
    let result .= '%#'.hl.'#%('.substitute(text, '%', '%%', 'g').'%)'

    if result_width > winwidth | break | endif
  endfor

  return result
endfu

fu! esearch#ui#render#table(mt) abort
  let mt = deepcopy(a:mt)
  let cols_count = len(mt[0])
  let widths = repeat([[]], len(mt))
  let max_width = repeat([0], cols_count)

  for i in range(len(mt))
    let widths[i] = repeat([0], len(mt[i]))

    for j in range(len(mt[i]))
      let widths[i][j] = s:List.foldl({a, pair-> a + strdisplaywidth(pair[0])}, 0, mt[i][j])

      let max_width[j] = max([widths[i][j], max_width[j]])
    endfor
  endfor

  " PP
  let result = []
  for i in range(len(mt))
    for j in range(cols_count - 1)
      let col = mt[i][j]
      let col[-1][0] .= repeat(' ', max_width[j] + 2 - widths[i][j])
      let result += col
    endfor
    let result += mt[i][cols_count - 1] + [["\n", 'None']]
  endfor
  return result
endfu
