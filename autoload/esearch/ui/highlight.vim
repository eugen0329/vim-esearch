fu! esearch#ui#highlight#init(opts) abort
  let s:state = ["\<plug>None", 0, []]
  let [s:re, s:word, s:err] = [a:opts.re, a:opts.word, a:opts.err]
endfu

fu! esearch#ui#highlight#words(str) abort
  let [col1, chunks] = s:state[1] == 0 || stridx(a:str, s:state[0]) != 0
        \ ? s:words(a:str, 0, [])
        \ : s:words(a:str, s:state[1], s:state[2])
  if empty(chunks) | return [] | endif
  let s:state = [a:str, col1, chunks[:(chunks[-1][0] == col1 ? -2 : -1)]]

  return chunks
endfu

fu! s:words(str, col2, chunks) abort
  let [last_col1, col2] = [a:col2, a:col2]

  while 1
    let [token, col1, col2] = matchstrpos(a:str, s:re, col2)
    if col2 == -1 | return [last_col1, a:chunks] | endif

    let err_hl = s:err(token)
    if !empty(err_hl) | return [0, [[0, len(a:str), err_hl]]] | endif

    let word_hl = s:word(token)
    if !empty(word_hl) | call add(a:chunks, [col1, col2, word_hl]) | endif
    let last_col1 = col1
  endw
endfu
