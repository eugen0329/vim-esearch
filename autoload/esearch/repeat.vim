" Wrapper around Tim Pope's vim-repeat with fallback to minimal functionality to
" avoid hard dependency

fu! esearch#repeat#run(count) abort
  try
    let result = repeat#run(a:count)
    if type(result) ==# type('') | return result | endif
    return ''
  catch /E117:/
    if !exists('s:changedtick') || s:changedtick != b:changedtick
      return 'norm! '.(a:count ? a:count : '').'.'
    else
      return 'norm '.(a:count ? a:count : (s:count ? s:count : '')) 
            \.'"'.get(s:reg, s:seq, esearch#util#clipboard_reg()).s:seq
    endif
  endtry
endfu

fu! esearch#repeat#set(seq, count) abort
  try
    return repeat#set(a:seq, a:count)
  catch /E117:/
    let [s:changedtick, s:seq, s:count] = [b:changedtick, a:seq, a:count]
  endtry
endfu

fu! esearch#repeat#setreg(seq, reg) abort
  try
    return repeat#setreg(a:seq, a:reg)
  catch /E117:/
    let s:reg = {}
    let s:reg[a:seq] = a:reg
  endtry
endfu
