let s:linenr_format = ' %3d %s'

fu! esearch#out#win#render#viml#do(bufnr, data, from, to, esearch) abort
  let parsed = a:esearch.parse(a:data, a:from, a:to)

  let line = line('$') + 1

  let i = 0
  let limit = len(parsed)
  let lines = []

  while i < limit
    let filename = parsed[i].filename

    if g:esearch_win_ellipsize_results
      let text = esearch#util#ellipsize(
            \ parsed[i].text,
            \ parsed[i].col,
            \ a:esearch.context_width.left,
            \ a:esearch.context_width.right,
            \ g:esearch#util#ellipsis)
    else

      let text = parsed[i].text
    endif

    if filename !=# a:esearch.contexts[-1].filename
      let a:esearch.contexts[-1].end = line

      if a:esearch.highlights_enabled &&
            \ len(a:esearch.contexts) > g:esearch_win_disable_context_highlights_on_files_count
        let a:esearch.highlights_enabled = 0
        call s:unload_highlights(a:esearch)
      end

      call add(lines, '')
      call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
      " call add(a:esearch.columns_map, 0)
      call add(a:esearch.line_numbers_map, 0)
      let line += 1

      call add(lines, filename)
      call esearch#out#win#add_context(a:esearch.contexts, filename, line)
      let a:esearch.context_by_name[filename] = a:esearch.contexts[-1]
      call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
      " call add(a:esearch.columns_map, 0)
      call add(a:esearch.line_numbers_map, 0)
      let a:esearch.files_count += 1
      let line += 1
      let a:esearch.contexts[-1].filename = filename
    endif

    call add(lines, printf(s:linenr_format, parsed[i].lnum, text))
    " call add(a:esearch.columns_map, parsed[i].col)
    call add(a:esearch.line_numbers_map, parsed[i].lnum)
    call add(a:esearch.context_ids_map, a:esearch.contexts[-1].id)
    let a:esearch.contexts[-1].lines[parsed[i].lnum] = parsed[i].text
    let line += 1
    let i    += 1
  endwhile

  call esearch#util#append_lines(lines)
endfu

