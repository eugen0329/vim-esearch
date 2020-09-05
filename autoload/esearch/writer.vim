let s:Handle = esearch#buf#handle()
let s:by_key = function('esearch#util#by_key')

fu! esearch#writer#do(diff, esearch, bang) abort
  return s:Writer.new(a:diff, a:esearch).write(a:bang)
endfu

let s:Writer = {}

fu! s:Writer.new(diff, esearch) abort
  return extend(copy(self), {'diff': a:diff, 'esearch': a:esearch})
endfu

fu! s:Writer.write(bang) abort dict
  let cwd = self.esearch.cwd
  let self.conflicts = []
  let contexts = self.diff.contexts
  let WriteCb = self.esearch.write_cb

  let [current_buffer, current_window] = [esearch#buf#stay(), esearch#win#stay()]
  call esearch#util#doautocmd('User esearch_write_pre')
  try
    for [id, ctx] in sort(items(contexts), s:by_key)
      let path = esearch#out#win#view_data#filename(self.esearch, ctx.original)
      if !self.verify_readable(ctx, path) | continue | endif

      let buf = s:Handle.new(path)
      if !self.verify_not_modified(ctx, buf) | continue | endif

      if !empty(ctx.modified) | call self.replace_lines(ctx.modified, buf) | endif
      if !empty(ctx.deleted)  | call self.delete_lines(ctx.deleted, buf)  | endif
      if !empty(WriteCb) | call WriteCb(buf, a:bang) | endif
    endfor
  finally
    call current_window.restore()
    call current_buffer.restore()
  endtry
  call self.log()
  " Deferring is required to execute the autocommand with avoiding BufWriteCmd side effects
  call esearch#util#try_defer(function('esearch#util#doautocmd'), 'User esearch_write_post')
endfu

fu! s:Writer.log() abort dict
  if empty(self.conflicts)
    call esearch#util#warn('Done.')
    return setbufvar(self.esearch.bufnr, '&modified', 0)
  end

  let reasons = map(self.conflicts, 'printf("\n\t%s (%s)", v:val.filename, v:val.reason)')
  let message = "Can't write changes to the following files:".join(reasons, '')
  call esearch#util#warn(message)
endfu

fu! s:Writer.verify_readable(ctx, path) abort dict
  if filereadable(a:path) | return 1 | endif
  if get(a:ctx.original, 'rev')
    call add(self.conflicts, {'filename': a:path, 'reason': 'is a git blob'})
  else
    call add(self.conflicts, {'filename': a:path, 'reason': 'is not readable'})
  endif
  return 0
endfu

fu! s:Writer.verify_not_modified(ctx, buf) abort dict
  let original_lines = a:ctx.original.lines
  for modified_line in a:ctx.deleted + keys(a:ctx.modified)
    if a:buf.getline(modified_line) ==# original_lines[modified_line] | continue | endif

    call add(self.conflicts, {
          \ 'filename': a:ctx.filename,
          \ 'reason':   'line '.modified_line.' has changed',
          \})
    return 0
  endfor

  return 1
endfu

fu! s:Writer.replace_lines(modified, buf) abort dict
  for [lnum, text] in reverse(sort(items(a:modified), s:by_key))
    call a:buf.setline(lnum, text)
  endfor
  if !has_key(a:buf, 'lnum') || lnum < a:buf.lnum
    call extend(a:buf, {'lnum': lnum, 'text': text})
  endif
endfu

fu! s:Writer.delete_lines(deleted, buf) abort dict
  for lnum in reverse(sort(a:deleted, 'N'))
    call a:buf.deleteline(lnum)
  endfor
  if !has_key(a:buf, 'lnum') || lnum < a:buf.lnum
    call extend(a:buf, {'lnum': lnum, 'text': '[deleted]'})
  endif
endfu
