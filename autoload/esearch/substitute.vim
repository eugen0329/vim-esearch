" TODO add highlight of the replaced text
fu! esearch#substitute#do(args, from, to, out)
  let line = a:from
  let limit = a:from > a:to ? a:from + 1 : a:to + 1

  let pushed = 0
  let root = tabpagenr()
  let last_modified_tab = tabpagenr()
  let opened_files = {}
  let prev_filename = ''
  let disable_autocmd = 'noautocmd '

  while line < limit
    exe line
    " call esearch#log({'line': line, 'line(".")': line('.'), 'getline(line)': getline(line),
    "       \ '=~a:out.file_entry': getline(line) =~# a:out.file_entry, 'root': root, 
    "       \ 'tabpagenr': tabpagenr(), 'pushed': pushed})
    redraw!
    if getline(line) =~# a:out.file_entry
      let not_found = 0

      let filename = a:out.filename()
      " call esearch#log({'filename': filename, 'opened_files': opened_files, 'line_number': a:out.line_number()})
      let already_opened = has_key(opened_files, filename)
      if already_opened
        exe disable_autocmd.'tabn'.opened_files[filename].'|'.a:out.line_number()
      else
        call a:out.open('$tabnew')
        let opened_files[filename] = tabpagenr()
      endif

      try
        exe 's'a:args
      catch /E486:/
        let not_found = 1
      catch
        echo 'Error'
      endtry

      if not_found && !already_opened
        let useless_tab = tabpagenr() 
        exe disable_autocmd.'tabn'.root
        exe disable_autocmd.'tabclose'.useless_tab
      else
        let last_modified_tab = tabpagenr()
        exe disable_autocmd.'tabn'.root
        if !pushed
          let pushed = 1
          " Push current search tab to the right (penultimate position,
          " before the newly opened) for more convenience
          let root = tabpagenr('$') - 1
          exe disable_autocmd.'tabm '.(root - 1 )
        endif
      endif

    endif
    let line += 1
  endwhile

  exe 'tabn'last_modified_tab
endfu
