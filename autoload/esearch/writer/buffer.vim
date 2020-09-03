fu! esearch#writer#buffer#write(diff, esearch) abort
  return s:BufferWriter.new(a:diff, a:esearch).write()
endfu

let s:BufferWriter = esearch#writer#base#import()

fu! s:BufferWriter.write() abort dict
  let cwd = self.esearch.cwd
  let self.conflicts = []

  for ctx in values(self.diff.contexts)
    let path = esearch#out#win#view_data#filename(self.esearch, ctx.original)
    if !self.verify_readable(ctx, path) | continue | endif

    exe 'keepalt keepjumps $tabnew ' path
    if !self.verify_not_modified(ctx, path) | continue | endif

    let self.modified_line = line('$')
    if !empty(ctx.modified) | call self.replace_lines(ctx.modified) | endif
    if !empty(ctx.deleted)  | call self.delete_lines(ctx.deleted)  | endif
    call cursor(self.modified_line, 1)
  endfor

  redraw!
  call self.log()
endfu

fu! s:BufferWriter.verify_not_modified(ctx, path) abort dict
  let original_lines = a:ctx.original.lines
  for modified_line in a:ctx.deleted + keys(a:ctx.modified)
    if getline(modified_line) !=# original_lines[modified_line]
      call add(self.conflicts, {
            \ 'filename': a:ctx.filename,
            \ 'reason':   'line '.modified_line.' has changed',
            \})
      return 0
    endif
  endfor

  return 1
endfu

fu! s:BufferWriter.replace_lines(modified) abort dict
  for [line, text] in items(a:modified)
    call setline(line, text)
  endfor

  let line = str2nr(min(keys(a:modified)))
  if !empty(line) | let self.modified_line = min([self.modified_line, line]) | endif
endfu

fu! s:BufferWriter.delete_lines(deleted) abort dict
  let lines = reverse(sort(a:deleted, 'N'))
  for line in lines
    call deletebufline(bufnr('%'), line)
  endfor
  let line = str2nr(lines[-1]) - 1
  if !empty(line) | let self.modified_line = min([self.modified_line, line]) | endif
endfu
