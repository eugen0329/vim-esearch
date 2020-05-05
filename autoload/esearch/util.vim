let s:List     = vital#esearch#import('Data.List')
let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#util#setline(_, lnum, text) abort
  call setline(a:lnum, a:text)
endfu

if has('nvim')
  fu! esearch#util#append_lines(lines) abort
    call nvim_buf_set_lines(0, -1, -1, 0, a:lines)
  endfu
else
  fu! esearch#util#append_lines(lines) abort
    for l in a:lines
      call append(line('$'), l)
    endfor
  endfu
endif

fu! esearch#util#ellipsize_end(text, max_len, ellipsis) abort
  if strchars(a:text) < a:max_len
    return a:text
  endif

  return a:text[: a:max_len - 1 - strchars(a:ellipsis)] . a:ellipsis
endfu

fu! esearch#util#ellipsize(text, col, left, right, ellipsis) abort
  if strchars(a:text) < a:left + a:right
    return a:text
  endif

  if a:col - 1 < a:left
    " if unused room to the left - extending the right side
    let extended_right_index = a:left + a:right - 1
    if extended_right_index + 1 >= strchars(a:text)
      return a:text[: extended_right_index]
    else
      return a:text[: extended_right_index - strchars(a:ellipsis)] . a:ellipsis
    endif
  elseif a:col + a:right >= strchars(a:text)
    " if unused room to the right - extending the left side
    let extended_left_index = strchars(a:text) - a:left - a:right
    if extended_left_index == 0
      return a:text[strchars(a:ellipsis) + extended_left_index :]
    else
      return a:ellipsis . a:text[strchars(a:ellipsis) + extended_left_index :]
    endif
  else
    return    a:ellipsis
          \ . a:text[a:col - a:left + strchars(a:ellipsis) : a:col + a:right - 1 - strchars(a:ellipsis)]
          \ . a:ellipsis
  endif
endfu

fu! esearch#util#clip(value, from, to) abort
  " is made inclusive to be compliant with vim internal functions
  if a:value >= a:to
    return a:to
  elseif a:value <= a:from
    return a:from
  else
    return a:value
  endif
endfu

fu! esearch#util#timenow() abort
  let now = reltime()
  return str2float(reltimestr([now[0] % 10000, now[1]/1000 * 1000]))
endfu

fu! esearch#util#region_text(region) abort
  let options = esearch#let#restorable({'@@': '', '&selection': 'inclusive'})

  try
    if esearch#util#is_visual(a:region.type)
      silent exe 'normal! gvy'
    elseif a:region.type ==# 'line'
      silent exe "normal! '[V']y"
    else
      silent exe 'normal! `[v`]y'
    endif

    return @@
  finally
    call options.restore()
  endtry
endfu

fu! esearch#util#type2region(type) abort
  if esearch#util#is_visual(a:type)
    return {'type': a:type, 'begin': "'<", 'end': "'>"}
  elseif a:type ==# 'line'
    return {'type': a:type, 'begin': "'[", 'end': "']"}
  else
    return {'type': a:type, 'begin': '`[', 'end': '`]'}
  endif
endfu

fu! esearch#util#operator_expr(operatorfunc) abort
  if mode(1)[:1] ==# 'no'
    return 'g@'
  elseif mode() ==# 'n'
    let &operatorfunc = a:operatorfunc
    return 'g@'
  else
    return ":\<C-u>call ".a:operatorfunc."(visualmode())\<CR>"
  endif
endfu

fu! esearch#util#is_visual(mode) abort
  return a:mode =~? "^[vs\<C-v>]$"
endfu

fu! esearch#util#slice(dict, keys) abort
  return filter(copy(a:dict), 'index(a:keys, v:key) >= 0')
endfu

fu! esearch#util#compare_len(first, second) abort
  let a = len(a:first)
  let b = len(a:second)
  return a == b ? 0 : a > b ? 1 : -1
endfu

" abolish.vim
fu! esearch#util#buff_words() abort
  let words = []
  let lnum = line('w0')
  while lnum <= line('w$')
    let line = getline(lnum)
    let col = 0
    while match(line,'\<\k\k\+\>',col) != -1
      let words += [matchstr(line,'\<\k\k\+\>',col)]
      let col = matchend(line,'\<\k\k\+\>',col)
    endwhile
    let lnum += 1
  endwhile

  return s:List.uniq(words)
endfu

if !exists('g:esearch#util#ellipsis')
  if g:esearch#has#unicode
    let g:esearch#util#ellipsis = g:esearch#unicode#ellipsis
  else
    let g:esearch#util#ellipsis = '|'
  endif
endif

" prevent output of {...} and [...] for recursive references
if has('nvim')
  fu! s:fix_recursive_reference_output(list_or_dict) abort
    return a:list_or_dict
  endfu
else
  fu! s:fix_recursive_reference_output(list_or_dict) abort
    " See :h string() for more details
    return deepcopy(a:list_or_dict)
  endfu
endif

if has('nvim')
  fu! esearch#util#getchar() abort
    return s:to_char(getchar())
  endfu
else
  fu! esearch#util#getchar() abort
    let char = getchar()

    if empty(esearch#map#escape_kind(char))
      return s:to_char(char)
    endif

    return char
  endfu
endif

fu! s:to_char(getchar_output) abort
  if type(a:getchar_output) ==# type('')
    return a:getchar_output
  endif
  return nr2char(a:getchar_output)
endfu

fu! esearch#util#insert(list, items, index) abort
  let i = len(a:items) - 1
  let list = a:list

  while i >= 0
    let list = insert(list, a:items[i], a:index)
    let i -= 1
  endwhile

  return list
endfu

fu! esearch#util#safe_undojoin() abort
  try
    undojoin
  catch /E790:/
  endtry
endfu

fu! esearch#util#safe_matchdelete(id) abort
  if a:id < 1 | return | endif " E802

  try
    call matchdelete(a:id)
  catch /E803:/
  endtry
endfu

fu! esearch#util#abspath(cwd, path) abort
  if s:Filepath.is_absolute(a:path)
    return a:path
  endif

  return s:Filepath.join(a:cwd, a:path)
endfu

" TODO consider to extract to utils
fu! esearch#util#readfile(filename, cache) abort
  let key = [a:filename, getfsize(a:filename), getftime(a:filename)]

  if a:cache.has(key)
    let lines = a:cache.get(key)
  else
    let lines = readfile(a:filename)
    call a:cache.set(key, lines)
  endif

  return lines
endfu

" Is DANGEROUS as it can cause editing file with an existing swap, required ONLY
" for floating preview windows
fu! esearch#util#silence_swap_prompt() abort
  " A - suppress swap prompt
  " F - don't echo that a:filename is edited
  return esearch#let#restorable({'&shortmess': 'AF'})
endfu

fu! esearch#util#slice_factory(keys) abort
  let private_scope = {}
  exe    " fu! l:private_scope.slice(dict) abort\n"
     \ . '   return esearch#util#slice(a:dict,'.string(a:keys).")\n"
     \ . ' endfu'
  return private_scope.slice
endfu

fu! esearch#util#pluralize(word, count) abort
  let word = a:word

  if a:count == 1 || empty(word)
    return word
  endif

  " tim pope
  let word = substitute(word, '\v\C[aeio]@<!y$',     'ie',  '')
  let word = substitute(word, '\v\C%(nd|rt)@<=ex$',  'ice', '')
  let word = substitute(word, '\v\C%([sxz]|[cs]h)$', '&e',  '')
  let word = substitute(word, '\v\Cf@<!f$',          've',  '')
  let word .= 's'
  return word
endfu

if g:esearch#has#nomodeline
  fu! esearch#util#doautocmd(expr) abort
    exe 'silent doau <nomodeline> ' . a:expr
  endfu
else
  fu! esearch#util#doautocmd(expr) abort
    let original_modelines = &modelines
    try
      set modelines=0
      exe 'silent doau ' . a:expr
    finally
      let &modelines = original_modelines
    endtry
  endfu
endif
