let s:Log  = esearch#log#import()

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#writer#buffer#write(diff, esearch) abort
  return s:new(a:diff, a:esearch).write()
endfu

fu! s:new(diff, esearch) abort
  return {
        \ 'diff':                  a:diff,
        \ 'esearch':               a:esearch,
        \ 'modified_line':         s:null,
        \ 'write':                 function('<SID>write'),
        \ 'replace_lines':         function('<SID>replace_lines'),
        \ 'delete_lines':          function('<SID>delete_lines'),
        \ 'try_jump_to_diff_line': function('<SID>try_jump_to_diff_line'),
        \ 'detect_conflict':       function('<SID>detect_conflict'),
        \}
endfu

fu! s:write() abort dict
  let cwd = self.esearch.cwd
  let conflicts = []

  for [id, ctx] in items(self.diff.contexts)
    let path = esearch#util#abspath(cwd, ctx.filename)
    exe '$tabnew ' . path

    let conflict = self.detect_conflict(ctx, path)
    if conflict isnot# s:null
      call add(conflicts, conflict)
      continue
    endif

    if !empty(get(ctx, 'modified', {}))
      call self.replace_lines(ctx.modified)
    endif
    call self.try_jump_to_diff_line()

    if !empty(get(ctx, 'deleted', []))
      call self.delete_lines(ctx.deleted)
    endif
    call self.try_jump_to_diff_line()

    let self.modified_line = s:null
  endfor
  redraw!

  if empty(conflicts)
    call setbufvar(self.esearch.bufnr, '&modified', 0)
  else
    let reasons_texts =
          \ map(conflicts, 'printf("\n\t%s (%s)", v:val.filename, v:val.reason)')
    let message = "Can't write changes to the following files:"
          \ . join(reasons_texts, '')
    call s:Log.echo('ErrorMsg',  message)
  endif
endfu

fu! s:detect_conflict(ctx, path) abort dict
  if !filereadable(a:path)
    return {
          \ 'filename': a:ctx.filename,
          \ 'reason':   'is not readable',
          \ }
  endif

  let original_lines = a:ctx.original.lines
  for changed_line_number in a:ctx.deleted + keys(a:ctx.modified)
    if getline(changed_line_number) !=# original_lines[changed_line_number]
      return {
            \ 'filename': a:ctx.filename,
            \ 'reason':   'line ' . changed_line_number . ' has changed',
            \ }
    endif
  endfor

  return s:null
endfu

fu! s:try_jump_to_diff_line() abort dict
  if self.modified_line isnot# s:null && line('.') != self.modified_line
    call cursor(self.modified_line, 1)
  endif
endfu

fu! s:replace_lines(modified) abort dict
  let lines_with_text_to_replace = items(a:modified)

  for [line, text] in lines_with_text_to_replace
    call setline(line, text)
  endfor

  if self.modified_line is# s:null
    let [first_replaced_line, _text] = lines_with_text_to_replace[0]
    let self.modified_line = first_replaced_line
  endif
endfu

fu! s:delete_lines(deleted) abort dict
  let lines_to_delete = reverse(sort(a:deleted, 'N'))

  for line in lines_to_delete
    call deletebufline(bufnr('%'), line)
  endfor

  if self.modified_line is# s:null
    let self.modified_line = max([1, lines_to_delete[0] - 1])
  endif
endfu
