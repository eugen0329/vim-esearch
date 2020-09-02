fu! esearch#writer#file#write(diff, esearch) abort
  return s:FileWriter.new(a:diff, a:esearch).write()
endfu

let s:FileWriter = {}

fu! s:FileWriter.new(diff, esearch) abort
  return  extend(copy(self), {'diff': a:diff, 'esearch': a:esearch})
endfu

fu! s:FileWriter.write() abort dict
  let cwd = self.esearch.cwd
  let self.conflicts = []

  for [_, ctx] in items(self.diff.contexts)
    let path = esearch#util#abspath(cwd, ctx.filename)
    if !self.verify_readable(path) | continue | endif

    let file = readfile(path)
    if !self.verify_modified(file, ctx) | continue | endif

    if !empty(ctx.modified) | call self.replace_lines(file, ctx.modified) | endif
    if !empty(ctx.deleted)  | call self.delete_lines(file,  ctx.deleted)  | endif

    call self.writefile(file, path)
  endfor

  call self.log()
  checktime
endfu

fu! s:FileWriter.log() abort dict
  if empty(self.conflicts)
    call esearch#util#warn('Done.')
    return setbufvar(self.esearch.bufnr, '&modified', 0)
  end

  let reasons =
        \ map(self.conflicts, 'printf("\n\t%s (%s)", v:val.filename, v:val.reason)')
  let message = "Can't write changes to the following files:"
        \ . join(reasons, '')
  call esearch#util#warn(message)
endfu

fu! s:FileWriter.writefile(file, path) abort dict
  if writefile(a:file, a:path) == 0 | return | endif
  call add(self.conflicts, "Can't write file " . a:path)
endfu

fu! s:FileWriter.verify_readable(path) abort dict
  if filereadable(a:path) | return 1 | endif
  call add(self.conflicts, {'filename': a:path, 'reason': 'is not readable'})
  return 0
endfu

fu! s:FileWriter.verify_modified(file, ctx) abort dict
  let original_lines = a:ctx.original.lines
  for changed_line in a:ctx.deleted + keys(a:ctx.modified)
    if a:file[changed_line-1] !=# original_lines[changed_line]
      call add(self.conflicts, {
            \ 'filename': a:ctx.filename,
            \ 'reason':   'line ' . changed_line . ' has changed',
            \})
      return 0
    endif
  endfor

  return 1
endfu

fu! s:FileWriter.replace_lines(file, modified) abort dict
  for [line, text] in items(a:modified)
    let a:file[line - 1] = text
  endfor
endfu

fu! s:FileWriter.delete_lines(file, deleted) abort dict
  for line in reverse(sort(a:deleted, 'N'))
    call remove(a:file, line - 1)
  endfor
endfu
