let s:Prelude    = vital#esearch#import('Prelude')
let s:Highlight  = vital#esearch#import('Vim.Highlight')
let s:Message    = vital#esearch#import('Vim.Message')
let s:Filepath   = vital#esearch#import('System.Filepath')

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

" borrowed from the airline
fu! esearch#util#qftype(bufnr) abort
  let buffers = s:Message.capture('silent ls')

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
      " TODO refactor to check variable value instead of existance
      " @vimlint(EVL102, 1, l:empty)
      let empty = 1
      " @vimlint(EVL102, 0, l:empty)
    else
      let seen[a:list[i]] = 1
      let i += 1
    endif
  endwhile
  return a:list
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

fu! esearch#util#shellescape(str) abort
  return escape(fnameescape(a:str), ';')
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
    echohl NONE
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

fu! esearch#util#copy_highlight(from, to, options) abort
  let new_highlight = {'name': a:from, 'attrs': s:Highlight.get(a:to).attrs}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! esearch#util#set_highlight(name, attributes, options) abort
  let attributes = filter(a:attributes, '!empty(v:val)')
  let new_highlight = {'name': a:name, 'attrs': attributes}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! esearch#util#get_highlight(hightlight_name) abort
  return s:Highlight.get(a:hightlight_name).attrs
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
" Algorithm:
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
"        If they're eql, then the first required value is found,
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

fu! s:is_key_combination(group, c) abort
  return index(a:group, a:c[:-2]) >= 0 || index(a:group, a:c) >= 0
endfu

fu! esearch#util#escape_kind(char) abort
  let printable = strtrans(a:char)

  let super_prefix = strtrans("\<D-a>")[:-2]
  let meta_prefix = strtrans("\<M-a>")[:-2]
  let ameta_prefix = strtrans("\<A-a>")[:-2]

  let meta_prefix_re = '^\%('
        \ . meta_prefix . '\|'
        \ . super_prefix . '\|'
        \ . ameta_prefix . '\)'

  let metas = [meta_prefix, ameta_prefix, super_prefix]
  let shifts = []
  let controls = []

   let chars = [
         \ 'Nul',
         \ 'BS',
         \ 'Tab',
         \ 'NL',
         \ 'FF',
         \ 'CR',
         \ 'Return',
         \ 'Enter',
         \ 'Esc',
         \ 'Space',
         \ 'lt',
         \ 'Bslash',
         \ 'Bar',
         \ 'Del',
         \ 'CSI',
         \ 'xCSI',
         \ 'Up',
         \ 'Down',
         \ 'Left',
         \ 'Right',
         \ 'Help',
         \ 'Undo',
         \ 'Insert',
         \ 'Home',
         \ 'End',
         \ 'PageUp',
         \ 'PageDown',
         \ 'kUp',
         \ 'kDown',
         \ 'kLeft',
         \ 'kRight',
         \ 'kHome',
         \ 'kEnd',
         \ 'kOrigin',
         \ 'kPageUp',
         \ 'kPageDown',
         \ 'kDel',
         \ 'kPlus',
         \ 'kMinus',
         \ 'kMultiply',
         \ 'kDivide',
         \ 'kPoint',
         \ 'kComma',
         \ 'kEqual',
         \ 'kEnter',
         \ ]

   for c in chars
     call add(metas, strtrans(eval('"\<M-'.c.'>"')))
     call add(metas, strtrans(eval('"\<A-'.c.'>"')))
     call add(metas, strtrans(eval('"\<D-'.c.'>"')))
     call add(shifts, strtrans(eval('"\<S-'.c.'>"')))
     call add(controls, strtrans(eval('"\<C-'.c.'>"')))
   endfor

   for i in range(0,9)
     call add(metas, strtrans(eval('"\<M-k'.i.'>"')))
     call add(metas, strtrans(eval('"\<A-k'.i.'>"')))
     call add(metas, strtrans(eval('"\<D-k'.i.'>"')))
     call add(shifts, strtrans(eval('"\<S-k'.i.'>"')))
     call add(controls, strtrans(eval('"\<C-k'.i.'>"')))
   endfor

   let fs = []
   for i in range(1,12)
     call add(fs, strtrans(eval('"\<F'.i.'>"')))
     call add(metas, strtrans(eval('"\<M-F'.i.'>"')))
     call add(metas, strtrans(eval('"\<A-F'.i.'>"')))
     call add(metas, strtrans(eval('"\<D-F'.i.'>"')))
     call add(shifts, strtrans(eval('"\<S-F'.i.'>"')))
     call add(controls, strtrans(eval('"\<C-F'.i.'>"')))
   endfor

   if printable =~# meta_prefix_re || s:is_key_combination(metas, printable)
     return 'meta'
   elseif s:is_key_combination(shifts, printable)
     return 'shift'
   elseif a:char =~# '^[[:cntrl:]]' || s:is_key_combination(controls, printable)
     return 'control'
   elseif s:is_key_combination(fs, printable)
      return 'f'
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

if !exists('g:esearch#util#ellipsis')
  if g:esearch#has#unicode
    let g:esearch#util#ellipsis = g:esearch#unicode#ellipsis
  else
    let g:esearch#util#ellipsis = '|'
  endif
endif

let g:esearch#util#mockable = {}
fu! g:esearch#util#mockable.echo(string) abort
  echo a:string
endfu

fu! esearch#util#parse_help_options(command) abort
  let options = {}
  let option = '-\{1,2}[0-9a-zA-Z][0-9a-zA-Z-]*'
  let option_regexp = '\('.option.'\)'
  let the_rest_regexp = '\(.*\)'
  let option_and_the_rest_regexp = option_regexp . the_rest_regexp
  " TODO do we need to allow options outputted without left padding?
  let options_area_regexp = '^[ \t]\+\%(' . option . '[\[\]=\w]*\|[, ]\+\)\+'

  for line in split(system(a:command), "\n")
    " let padded  = match(line, '^[\t ]+') > -1
    " TODO do we need to allow options outputted without left padding?
    " if !padded
    "   continue
    " endif

    let aliases = []
    let options_area  = matchstr(line, options_area_regexp)

    while len(options_area) > 0
      let matches = matchlist(options_area, option_and_the_rest_regexp)

      " [full_line, matched_option, the_rest_of_a_line, ...] = matches
      if len(matches) > 1 && !empty(matches[1])
        call add(aliases,  matches[1])
        let options_area = matches[2]
      else
        break
      endif
    endwhile

    if !empty(aliases)
      let option_info = {'aliases': aliases, 'padded': -1 }
      for alias in aliases
        let options[alias] = s:fix_recursive_reference_output(option_info)
      endfor
    endif
  endfor

  return options
endfu

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
    if esearch#util#escape_kind(char) isnot 0
      return char
    else
      return s:to_char(char)
    endif
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
  if a:id < 0 | return | endif

  try
    call matchdelete(a:id)
  catch /E803:/
  endtry
endfu

" TODO coverage
fu! esearch#util#find_root(path, markers) abort
  " Partially based on vital's prelude path2project-root internals
  let start_dir = s:Prelude.path2directory(a:path)
  " TODO rewrite to return start_dir when ticket with fixing cwd handling is
  " ready
  if empty(a:markers) | return a:path | endif

  let dir = start_dir
  let max_depth = 50
  let depth = 0

  while depth < max_depth
    for marker in a:markers
      let file = globpath(dir, marker, 1)

      if file !=# ''
        return s:Prelude.substitute_path_separator(fnamemodify(file, ':h'))
      endif
    endfor

    let dir_upwards = fnamemodify(dir, ':h')
    " if it's fs root - use start_dir
    if dir_upwards == dir
      return start_dir
    endif
    let dir = dir_upwards
    let depth += 1
  endwhile

  return start_dir
endfu

fu! esearch#util#absolute_path(cwd, path) abort
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

fu! esearch#util#lcd(path) abort
  return s:DirectoryGuard.store(a:path)
endfu

let s:DirectoryGuard = {'cwd': ''}

fu! s:DirectoryGuard.store(path) abort dict
  let instance = copy(self)

  if !empty(a:path)
    let instance.cwd = getcwd()
    exe 'lcd ' . a:path
  endif

  return instance
endfu

fu! s:DirectoryGuard.restore() abort dict
  if !empty(self.cwd)
    exe 'lcd ' . self.cwd
  endif
endfu
