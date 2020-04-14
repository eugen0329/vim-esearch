let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#render#viml#do(bufnr, data, from, to, esearch) abort
  let original_cwd = esearch#util#lcd(a:esearch.cwd)
  try
    let [parsed, separators_count] = a:esearch.parse(a:data, a:from, a:to)
    let a:esearch.separators_count += separators_count
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
              \ a:esearch.contexts[-1].id > g:esearch_win_disable_context_highlights_on_files_count
          call esearch#out#win#stop_highlights('too many lines')
        end

        call add(lines, '')
        call add(a:esearch.ctx_ids_map, a:esearch.contexts[-1].id)
        call add(a:esearch.line_numbers_map, 0)
        let line += 1

        call add(lines, fnameescape(filename))
        call esearch#out#win#render#add_context(a:esearch.contexts, filename, line)
        let a:esearch.context_by_name[filename] = a:esearch.contexts[-1]
        call add(a:esearch.ctx_ids_map, a:esearch.contexts[-1].id)
        call add(a:esearch.line_numbers_map, 0)
        let a:esearch.files_count += 1
        let line += 1
        let a:esearch.contexts[-1].filename = filename
      endif

      if len(text) > g:unload_context_syntax_on_line_length
        if len(text) > g:unload_global_syntax_on_line_length && a:esearch.highlights_enabled
          let a:esearch.highlights_enabled = 1
          call esearch#out#win#stop_highlights('too long line encountered')
        else
          let a:esearch.contexts[-1].syntax_loaded = -1
        end
      end

      call add(lines, printf(g:esearch#out#win#entry_format, parsed[i].lnum, text))
      call add(a:esearch.line_numbers_map, parsed[i].lnum)
      call add(a:esearch.ctx_ids_map, a:esearch.contexts[-1].id)
      let a:esearch.contexts[-1].lines[parsed[i].lnum] = parsed[i].text
      let line += 1
      let i    += 1
    endwhile
  finally
    call original_cwd.restore()
  endtry

  call esearch#util#append_lines(lines)
endfu
