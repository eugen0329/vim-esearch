let s:Buffer = vital#esearch#import('Vim.Buffer')
let s:Log = esearch#log#import()
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
  let filename = s:Filepath.to_slash(resolve(a:filename))
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

fu! esearch#buf#goto_or_open(buffer, opener, ...) abort
  let options = extend(copy(get(a:, 1, {})), {'opener': a:opener})
  let bufnr = esearch#buf#find(a:buffer)

  " Noop if the buffer is current
  if bufnr == bufnr('%') | return 1 | endif
  " Open if doesn't exist
  if bufnr == -1
    return s:Buffer.open(a:buffer, options)
  endif
  let [tabnr, winnr] = esearch#buf#tabwin(bufnr)
  " Open if closed
  if empty(winnr)
    return s:Buffer.open(a:buffer, options)
  endif
  " Locate if opened
  exe 'tabnext ' . tabnr
  exe winnr . 'wincmd w'
  return 1
endfu

fu! esearch#buf#open(buffer, opener, ...) abort
  let options = extend(copy(get(a:, 1, {})), {'opener': a:opener})
  return s:Buffer.open(a:buffer, options)
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
  silent exe 'file' fnameescape(a:name)
endfu

fu! esearch#buf#rename_qf(name) abort
  let w:quickfix_title = a:name
endfu

fu! s:bufdo(bufnr, cmd, bang) abort
  let cur_buffer = esearch#buf#stay()
  try
    exe a:bufnr 'bufdo' a:cmd.(a:bang ? '!' : '') |
    return 1
  catch   | call esearch#util#warn(v:exception) | return 0
  finally | call cur_buffer.restore()
  endtry
endfu

fu! esearch#buf#handle() abort
  return s:Handle
endfu

let s:Handle = {}

if g:esearch#has#bufadd && g:esearch#has#bufline_functions
  fu! s:Handle.for(bufnr) abort dict
    call bufload(a:bufnr)
    call setbufvar(a:bufnr, '&buflisted', 1) " required for bufdo
    return extend(copy(self), {'bufnr': a:bufnr, 'filename': bufname(a:bufnr), 'existed': 1})
  endfu

  fu! s:Handle.new(filename) abort dict
    let existed = bufexists(a:filename)
    let bufnr = bufadd(a:filename)
    call bufload(bufnr)
    call setbufvar(bufnr, '&buflisted', 1) " required for bufdo
    return extend(copy(self), {'bufnr': bufnr, 'filename': a:filename, 'existed': existed})
  endfu

  if exists('*nvim_buf_line_count')
    fu! s:Handle.oneliner() abort dict
      return nvim_buf_line_count(self.bufnr) == 1
    endfu
  elseif g:esearch#has#getbufinfo_linecount
    fu! s:Handle.oneliner() abort dict
      return getbufinfo(self.bufnr)[0].linecount == 1
    endfu
  else
    fu! s:Handle.oneliner() abort dict
      return getbufline(self.bufnr, 2) == []
    endfu
  endif

  fu! s:Handle.getline(lnum) abort dict
    return get(getbufline(self.bufnr, a:lnum), 0)
  endfu

  fu! s:Handle.setline(lnum, replacement) abort dict
    call setbufline(self.bufnr, a:lnum, a:replacement)
  endfu

  fu! s:Handle.appendline(lnum, texts) abort
    call appendbufline(self.bufnr, a:lnum, a:texts)
  endfu

  fu! s:Handle.deleteline(lnum) abort dict
    return deletebufline(self.bufnr, a:lnum)
  endfu

  fu! s:Handle.write(bang) dict abort
    return s:bufdo(self.bufnr, 'write', a:bang)
  endfu

  fu! s:Handle.open(opener, ...) dict abort
    let options = extend(copy(get(a:, 1, {})), {'opener': a:opener})
    return s:Buffer.open(self.bufnr, options)
  endfu

  fu! s:Handle.bdelete(...) dict abort
    return s:bufdo(self.bufnr, 'bdelete', get(a:, 1))
  endfu

  fu! s:Handle.bwipeout(...) dict abort
    return s:bufdo(self.bufnr, 'bwipeout', get(a:, 1))
  endfu
else
  fu! s:Handle.new(filename) abort dict
    let existed = bufexists(a:filename)
    call esearch#buf#open(a:filename, 'edit', {'mods': 'keepalt keepjumps'})
    setlocal buflisted
    return extend(copy(self), {'bufnr': bufnr('%'), 'filename': a:filename, 'existed': existed})
  endfu

  fu! s:Handle.getline(lnum) abort dict
    if bufnr('%') !=# self.bufnr | throw 'Wrong bufnr' | endif
    return getline(a:lnum)
  endfu

 fu! s:Handle.setline(lnum, replacement) abort dict
    if bufnr('%') !=# self.bufnr | throw 'Wrong bufnr' | endif
    return setline(a:lnum, a:replacement)
  endfu

  fu! s:Handle.deleteline(lnum) abort dict
    if bufnr('%') !=# self.bufnr | throw 'Wrong bufnr' | endif
    exe a:lnum 'delete'
  endfu

  fu! s:Handle.write(bang) dict abort
    if bufnr('%') !=# self.bufnr | throw 'Wrong bufnr' | endif
    exe 'write' (a:bang ? '!' : '')
  endfu

  fu! s:Handle.open(opener, ...) dict abort
    let options = extend(copy(get(a:, 1, {})), {'opener': a:opener})
    return s:Buffer.open(self.filename, options)
  endfu
endif

fu! esearch#buf#stay() abort
  return s:CurrentBufferGuard.new()
endfu

let s:CurrentBufferGuard = {}

fu! s:CurrentBufferGuard.new() abort dict
  return extend(copy(self), {'bufnr': bufnr('')})
endfu

fu! s:CurrentBufferGuard.restore() abort dict
  if self.bufnr != bufnr('') | exe self.bufnr 'buffer!' | endif
endfu
