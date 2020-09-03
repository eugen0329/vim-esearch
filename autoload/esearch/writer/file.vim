fu! esearch#writer#file#write(diff, esearch) abort
  return s:FileWriter.new(a:diff, a:esearch).write()
endfu

let s:FileWriter = esearch#writer#base#import()

fu! s:FileWriter.write() abort dict
  let cwd = self.esearch.cwd
  let self.conflicts = []

  for ctx in values(self.diff.contexts)
    let path = esearch#out#win#view_data#filename(self.esearch, ctx.original)
    if !self.verify_readable(ctx, path) | continue | endif

    let file = readfile(path)
    if !self.verify_not_modified(file, ctx) | continue | endif

    if !empty(ctx.modified) | call self.replace_lines(file, ctx.modified) | endif
    if !empty(ctx.deleted)  | call self.delete_lines(file,  ctx.deleted)  | endif

    call self.writefile(file, path)
  endfor

  call self.log()
  checktime
endfu

fu! s:FileWriter.writefile(file, path) abort dict
  if writefile(a:file, a:path) == 0 | return | endif
  call add(self.conflicts, "Can't write file " . a:path)
endfu

fu! s:FileWriter.verify_not_modified(file, ctx) abort dict
  let original_lines = a:ctx.original.lines
  for modified_line in a:ctx.deleted + keys(a:ctx.modified)
    if a:file[modified_line-1] !=# original_lines[modified_line]
      call add(self.conflicts, {
            \ 'filename': a:ctx.filename,
            \ 'reason':   'line ' . modified_line . ' has changed',
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
