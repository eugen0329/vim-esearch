let s:Buffer   = vital#esearch#import('Vim.Buffer')
let s:Log  = esearch#log#import()
let s:Filepath = vital#esearch#import('System.Filepath')

if g:esearch#has#bufadd
  fu! esearch#buf#find(filename) abort
    if !bufexists(a:filename) | return -1 | endif
    return bufadd(a:filename)
  endfu
else
  fu! esearch#buf#find(filename) abort
    return bufnr(esearch#buf#pattern(a:filename))
  endfu
endif

" :h file-pattern
fu! esearch#buf#pattern(filename) abort
  " Normalize the path (remove redundant path components like in foo/./bar) and
  " resolve links
  let filename = resolve(a:filename)

  " From :h file-pattern
  " Note that for all systems the '/' character is used for path separator (even
  " Windows). This was done because the backslash is difficult to use in a pattern
  " and to make the autocommands portable across different systems.
  let filename = s:Filepath.to_slash(filename)

  " From :h file-pattern:
  "   *          matches any sequence of characters; Unusual: includes path separators
  "   ?          matches any single character
  "   \?         matches a '?'
  "   .          matches a '.'
  "   ~          matches a '~'
  "   ,          separates patterns
  "   \,         matches a ','
  "   { }        like \( \) in a |pattern|
  "   ,          inside { }: like \| in a |pattern|
  "   \}         literal }
  "   \{         literal {
  "   \\\{n,m\}  like \{n,m} in a |pattern|
  "   \          special meaning like in a |pattern|
  "   [ch]       matches 'c' or 'h'
  "   [^ch]      match any character but 'c' and 'h'
  " Special file-pattern characters must be escaped: [ escapes to [[], not \[.
  let filename = escape(filename, '?*[],\')
  " replacing with \{ and \} or [{] and [}] doesn't work
  let filename = substitute(filename, '[{}]', '?', 'g')
  return '^' . filename . '$'
endfu

fu! esearch#buf#tabwin(bufnr) abort
  for tabnr in range(1, tabpagenr('$'))
    let buflist = tabpagebuflist(tabnr)
    if index(buflist, a:bufnr) >= 0
      for winnr in range(1, tabpagewinnr(tabnr, '$'))
        if buflist[winnr - 1] == a:bufnr | return [tabnr, winnr] | endif
      endfor
    endif
  endfor

  return [0, 0]
endf

fu! esearch#buf#goto_or_open(filename, opener, ...) abort
  let options = extend(copy(get(a:, 1, {})), {'opener': a:opener})
  let bufnr = esearch#buf#find(a:filename)

  " Noop if the buffer is current
  if bufnr == bufnr('%') | return 1 | endif
  " Open if doesn't exist
  if bufnr == -1
    return s:Buffer.open(a:filename, options)
  endif
  let [tabnr, winnr] = esearch#buf#tabwin(bufnr)
  " Open if closed
  if empty(winnr)
    return s:Buffer.open(a:filename, options)
  endif
  " Locate if opened
  exe 'tabnext ' . tabnr
  exe winnr . 'wincmd w'
  return 1
endfu

fu! esearch#buf#open(filename, opener, ...) abort
  let options = extend(copy(get(a:, 1, {})), {'opener': a:opener})
  return s:Buffer.open(a:filename, options)
endfu

" borrowed from the airline
fu! esearch#buf#qfbufnr() abort
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

fu! esearch#buf#qftype(bufnr) abort
  let buffers = s:Log.capture('silent ls')

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

fu! esearch#buf#rename(name) abort
  exe 'file' fnameescape(a:name)
endfu
