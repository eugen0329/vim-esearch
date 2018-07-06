" if !exists('g:esearch#util#use_setbufline')
"   let g:esearch#util#use_setbufline = 0
" endif
if !exists('g:esearch#util#trunc_omission')
  let g:esearch#util#trunc_omission = '⦚'
endif

"" Disagreeably inefficient. Consider to implement #setbuflines instead to reduce redundant buffer switches
"""""""""""""""""""""""""""""""""""""""""""""""""""
" if g:esearch#util#use_setbufline
"   fu! esearch#util#setline(expr, lnum, text) abort
"     let oldnr = winnr()
"     let winnr = bufwinnr(a:expr)

"     if oldnr != winnr
"       if winnr ==# -1
"         noau silent exec 'sp '.escape(bufname(bufnr(a:expr)), ' \`')
"         noau silent call setline(a:lnum, a:text)
"         noau silent hide
"       else
"         noau exec   winnr.'wincmd w'
"         noau silent call setline(a:lnum, a:text)
"       endif
"     else
"       noau silent! call setline(a:lnum, a:text)
"     endif
"     noau exec oldnr.'wincmd w'
"   endfu
" else
  fu! esearch#util#setline(_, lnum, text) abort
    return setline(a:lnum, a:text)
  endfu
" endif

" borrowed from the airline
fu! esearch#util#qftype(bufnr) abort
  redir => buffers
  silent ls
  redir END

  let nr = a:bufnr
  for buf in split(buffers, '\n')
    if match(buf, '\v^\s*'.nr) > -1
      if match(buf, '\cQuickfix') > -1
        return 'qf'
      elseif match(buf, '\cLocation') > -1
        return 'loc'
      else
        return 'reg'
      endif
    endif
  endfor
endfu

fu! esearch#util#qfbufnr() abort
  redir => buffers
  silent ls
  redir END

  for buf in split(buffers, '\n')
    if match(buf, '\cQuickfix') > -1
      return str2nr(matchlist(buf, '\s\(\d\+\)')[1])
    endif
  endfor
  return -1
endfu

fu! esearch#util#bufloc(bufnr) abort
  for tabnr in range(1, tabpagenr('$'))
    if tabpagenr() == tabnr | continue | endif
    let buflist = tabpagebuflist(tabnr)
    if index(buflist, a:bufnr) >= 0
      for winnr in range(1, tabpagewinnr(tabnr, '$'))
        if buflist[winnr - 1] == a:bufnr | return [tabnr, winnr] | endif
      endfor
    endif
  endfor

  return []
endf


fu! esearch#util#flatten(list) abort
  let flatten = []
  for elem in a:list
    if type(elem) == type([])
      call extend(flatten, esearch#util#flatten(elem))
    else
      call add(flatten, elem)
    endif
    unlet elem
  endfor
  return flatten
endfu

fu! esearch#util#uniq(list) abort
  let i = 0
  let seen = {}
  while i < len(a:list)
    if (a:list[i] ==# '' && exists('empty')) || has_key(seen,a:list[i])
      call remove(a:list,i)
    elseif a:list[i] ==# ''
      let i += 1
      let empty = 1
    else
      let seen[a:list[i]] = 1
      let i += 1
    endif
  endwhile
  return a:list
endfu

fu! esearch#util#btrunc(str, center, lw, rw) abort
  " om - omission, lw/rw - with from the left(right)
  let om = g:esearch#util#trunc_omission

  let l = (a:lw > a:center ? 0 : a:center - a:lw + len(om))
  let r = (len(a:str) <= a:center + a:rw ? len(a:str)-1 : a:center+a:rw-len(om))

  return (l == 0 ? '' : om) . a:str[l : r] . (r == len(a:str)-1 ? '' : om)
endfu

fu! esearch#util#trunc(str, size) abort
  if len(a:str) > a:size
    return a:str[:a:size] . '…'
  endif

  return a:str
endfu

fu! esearch#util#shellescape(str) abort
  return escape(fnameescape(a:str), ';')
  return shellescape(a:str, g:esearch.escape_special)
  return fnameescape(shellescape(a:str, g:esearch.escape_special))
endfu

fu! esearch#util#timenow() abort
  let now = reltime()
  return str2float(reltimestr([now[0] % 10000, now[1]/1000 * 1000]))
endfu

fu! esearch#util#has_unicode() abort
  return has('multi_byte') && (&termencoding ==# 'utf-8' || &encoding ==# 'utf-8')
endfu

fu! esearch#util#visual_selection() abort
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection ==# 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfu

fu! esearch#util#set(key, val) dict abort
  let self[a:key] = a:val
  return self
endfu

fu! esearch#util#get(key) dict abort
  return self[a:key]
endfu

fu! esearch#util#dict() dict abort
  return filter(copy(self), 'type(v:val) != '.type(function('tr')))
endfu

fu! esearch#util#with_val(val) dict abort
  let val = type(a:val) ==# type('') ? '"'.a:val.'"' : a:val
  return filter(copy(self), 'type(v:val) == type('.val.') && v:val==# '.val)
endfu

fu! esearch#util#without_val(val) dict abort
  let val = type(a:val) ==# type('') ? '"'.a:val.'"' : a:val
  return filter(copy(self), 'type(v:val) != type('.val.') || v:val!=# '.val)
endfu

fu! esearch#util#key(val) dict abort
  let val = type(a:val) ==# type('') ? '"'.a:val.'"' : a:val
  return get(keys(filter(copy(self), 'type(v:val) == type('.val.') && v:val==# '.val)), 0, 0)
endfu

fu! esearch#util#without(key) dict abort
  return filter(copy(self), 'v:key !=# "'.a:key.'"')
endfu

fu! esearch#util#slice(...) dict abort
  return filter(deepcopy(self), 'index(a:000, v:key) >= 0')
endfu

fu! esearch#util#set_default(key, default) dict abort
  if !has_key(self, a:key)
    let self[a:key] = a:default
  endif
  return self
endfu

fu! esearch#util#highlight(highlight, str, ...) abort
  exe 'echohl ' . a:highlight . '| echon ' . strtrans(string(a:str))
  if a:0 && empty(a:1)
    echohl 'Normal'
  endif
endfu


fu! esearch#util#hlecho(groups) abort
  for group in a:groups
    let str = len(group) == 1 ? '' : '| echon ' . string(group[1])
    let highlight = 'echohl ' . group[0]
    exe  highlight . str
  endfor
endfu

" Used to build adapter query query
fu! esearch#util#parametrize(key, ...) dict abort
  let option_index = g:esearch[a:key]
  return self[a:key]['p'][option_index]
endfu

" Used in cmdline prompt
fu! esearch#util#stringify(key, ...) dict abort
  let option_index = g:esearch[a:key]
  return self[a:key]['s'][option_index]
endfu

fu! esearch#util#highlight_attr(group, mode, what, default) abort
  let attr = synIDattr(synIDtrans(hlID(a:group)), a:what, a:mode)
  if attr ==# -1 || attr ==# ''
    return a:default
  endif
  return attr
endfu

fu! esearch#util#stringify_mapping(map) abort
  let str = substitute(a:map, '<[Cc]-\([^>]\)>', 'ctrl-\1 ', 'g')
  let str = substitute(str, '<[Ss]-\([^>]\)>', 'shift-\1 ', 'g')
  let str = substitute(str, '<[AMam]-\([^>]\)>', 'alt-\1 ', 'g')
  let str = substitute(str, '<[Dd]-\([^>]\)>', 'cmd-\1 ', 'g')
  let str = substitute(str, '\s\+$', '', 'g')
  return str
endfu

fu! esearch#util#destringify_mapping(map) abort
  let str = substitute(a:map, 'ctrl',           'C', 'g')
  let str = substitute(str,   '\%(alt\|meta\)', 'M', 'g')
  let str = substitute(str,   'shift',          'S', 'g')
  let str = substitute(str,   'cmd',            'D', 'g')
  let str = join(map(filter(split(str,' '), "v:val !=# ''"),"'<'.v:val.'>'"),'')
  return str
endfu

" Trying to infer which combination was pressed (<C-k>, <M-c> etc.)
" Required:
"   To figure out two values:
"   1. <{}- > - the first which refers to kind of shift (M - meta, C - control etc.)
"   2. <S-{}> - the second. This button is pressed along with a shift.
" Algorythm:
"   1. :let char = getchar()
"   2. Pressing <M-c> (as an example), content of char now is '<80><fc>^Hc'
"   3. Reveal unprintable chars by :let printable = strtrans(a:char)
"      The last caracter printable[-1:] is the second required value.
"   4. Walk through different combinations:
"        Suppose it was combination with meta, like <M-a>.
"        Comparing head of

"          strtrans("\<M-a>") (that returns '<80><fc>^Ha'
"                                          |  head   |tail (the last char)|)
"
"        with the head of the *printable*.
"
"          strtrans("\<M-a>")[:-2] == printable[:-2]
"
"        If they're eql, than the first required value is found,
"        else - try the following kind of shift in the same way.
"
fu! esearch#util#map_name(char) abort
  let printable = strtrans(a:char)

  let len = strlen(printable)
  let without_last_char = printable[:-2]
  let last_char = printable[-1:]

  if strtrans("\<M-a>")[:-2] == without_last_char
    return '<M-'.last_char.'>'
  elseif strtrans("\<F1>")[:-2] == without_last_char
    return '<F'.last_char.'>'
  elseif strtrans("\<S-F1>")[:-2] == without_last_char
    return '<S-f'.last_char.'>'
  elseif strtrans("\<S-F1>")[:-2] == without_last_char
    return '<S-f'.last_char.'>'
  elseif strtrans("\<C-a>")[:-2] == without_last_char
    return '<C-'.last_char.'>'
  endif

  return 0
endfu

" TODO handle <expr> mappings
fu! esearch#util#map_rhs(printable) abort
  let printable = a:printable

  " We can't fetch maparg neither with l:char nor with strtrans(l:char)
  let mapname = esearch#util#map_name(printable)
  if !empty(mapname)

    " Vim can't expand mappings if we have mapping like
    " maparg('<M-f>', 'c') == '<S-Left>' and "\<M-f>" send to
    " input() as an initial {text} argument, so we try to do it manually
    let maparg = maparg(mapname, 'c')
    if !empty(maparg)
      " let char = eval('"\'.maparg.'"')
      return eval('"\'.maparg.'"')
    endif
  endif

  return ''
endfu

fu! esearch#util#has_vimproc() abort
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc
endfu

fu! esearch#util#recognize_plug_manager() abort
  if exists('*plug#begin')
    return 'Vundle'
  elseif exists('*neobundle#begin')
    return 'NeoBundle'
  elseif exists('*dein#begin')
    return 'Dein'
  elseif exists('*vundle#begin')
    return 'Vundle'
  elseif exists('*pathogen#infect')
    return 'Pathogen'
  endif
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
  return esearch#util#uniq(words)
endfu

fu! esearch#util#add_map(mappings, lhs, rhs) abort
  for mapping in a:mappings
    if mapping.rhs == a:rhs && mapping.default == 1
      call remove(a:mappings, index(a:mappings, mapping))
      break
    endif
  endfor

  call add(a:mappings, {'lhs': a:lhs, 'rhs': a:rhs, 'default': 0})
endfu

fu! esearch#util#vim8_job_start_close_cb_implemented() abort
  " 7.4.1398 - Implemented close-cb
  return has('patch-7.4.1398')
endfu

fu! esearch#util#vim8_calls_close_cb_last() abort
  " 7.4.1787 - fix of: channel close callback is invoked before other callbacks
  return has('patch-7.4.1787')
endfu
