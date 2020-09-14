let s:Handle = esearch#buf#handle()
let s:by_key = function('esearch#util#by_key')

fu! esearch#writer#do(diffs, esearch, bang) abort
  return s:Writer.new(a:diffs, a:esearch).write(a:bang)
endfu

let s:Writer = {}

fu! s:Writer.new(diffs, esearch) abort
  return extend(copy(self), {'diffs': a:diffs, 'esearch': a:esearch})
endfu

fu! s:Writer.write(bang) abort dict
  let cwd = self.esearch.cwd
  let self.conflicts = []
  let WriteCb = self.esearch.write_cb

  let [current_buffer, current_window] = [esearch#buf#stay(), esearch#win#stay()]
  call esearch#util#doautocmd('User esearch_write_pre')
  try
    for [id, diff] in sort(items(self.diffs.by_id), s:by_key)
      let path = esearch#out#win#view_data#filename(self.esearch, diff.ctx)
      if !self.verify_readable(diff, path) | continue | endif

      let buf = s:Handle.new(path)
      if !a:bang
        if !self.verify_not_modified(diff, buf) | continue | endif
      endif

      for edit in diff.edits
        call call(buf[edit.func], edit.args)
      endfor
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

fu! s:Writer.verify_readable(diff, path) abort dict
  if filereadable(a:path) | return 1 | endif
  if get(a:diff.ctx, 'rev')
    call add(self.conflicts, {'filename': a:path, 'reason': 'is a git blob'})
  else
    call add(self.conflicts, {'filename': a:path, 'reason': 'is not readable'})
  endif
  return 0
endfu

fu! s:Writer.verify_not_modified(diff, buf) abort dict
  let ours_lines = a:diff.ctx.lines
  for edit in a:diff.edits
    if a:buf.getline(edit.lnum) is# ours_lines[edit.lnum] | continue | endif

    call add(self.conflicts, {
          \ 'filename': a:diff.ctx.filename,
          \ 'reason':   'line '.edit.lnum.' has changed',
          \})
    return 0
  endfor

  return 1
endfu
