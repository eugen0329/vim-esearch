" Two strategies of highlighting a search match:
"   - for view port only (only available for neovim)
"   - globally with matchadd
" The first strategy has some rendering delays caused by debouncing, but it's
" faster beacause regexps are not used.
" The second strategy causes freezes when long lines are rendered due to the
" lookbehind to prevent matching esearchLineNr virtual ui.
"
" Another option is to obtain the locations using adapter colorized output, but
" it cause uncontrolled freeze on backend callbacks due to redundant text with
" ANSI escape sequences.
fu! esearch#out#win#appearance#matches#init(esearch) abort
  if g:esearch_out_win_highlight_matches ==# 'viewport'
    let a:esearch.last_hl_range = [0,0]
    let a:esearch.matches_ns = luaeval('esearch.appearance.MATCHES_NS')
    let Callback = function('s:highlight_viewport_cb', [a:esearch])
    let a:esearch.hl_matches = esearch#debounce(Callback, g:esearch_win_matches_highlight_debounce_wait)

    aug esearch_win_hl_matches
      au CursorMoved <buffer> call b:esearch.hl_matches.apply()
    aug END
    call luaeval('esearch.appearance.buf_attach_matches()')
    return
  endif

  if g:esearch_out_win_highlight_matches ==# 'matchadd' && has_key(a:esearch.exp, 'vim_match')
    let a:esearch.matches_hl_id = matchadd('esearchMatch', a:esearch.exp.vim_match, -1)
  endif
endfu

fu! esearch#out#win#appearance#matches#uninit(esearch) abort
  if has_key(a:esearch, 'hl_matches')
    aug esearch_win_hl_matches
      au! * <buffer>
    aug END
    call a:esearch.hl_matches.cancel()
  endif

  if has_key(a:esearch, 'matches_hl_id')
    call esearch#util#safe_matchdelete(a:esearch.matches_hl_id)
  endif
endfu

fu! esearch#out#win#appearance#matches#soft_stop(esearch) abort
  call esearch#out#win#appearance#matches#uninit(a:esearch)
endfu

fu! s:highlight_viewport_cb(esearch) abort
  if !a:esearch.is_current()
    return
  endif

  let [top, bottom] = [ line('w0'), line('w$') ]
  let last_hl_range = a:esearch.last_hl_range

  if last_hl_range[0] <= top && bottom <= last_hl_range[1]
    return
  endif

  let exp = a:esearch.exp.vim
  let state = esearch#out#win#_state(a:esearch)
  let line_numbers_map = state.line_numbers_map
  let ctx_ids_map = state.ctx_ids_map
  let highlighted_lines_map = a:esearch.highlighted_lines_map

  let last_line = line('$')
  let line = esearch#util#clip(top - g:esearch_win_viewport_highlight_extend_by, 1, last_line)
  let end  = esearch#util#clip(bottom + g:esearch_win_viewport_highlight_extend_by, 1, last_line)
  let a:esearch.last_hl_range = [line, end]

  for text in nvim_buf_get_lines(0, line - 1, end, 0)
    let linenr =  line_numbers_map[line]
    let ctx_id = ctx_ids_map[line]

    if linenr ==# 0
      let line += 1
      continue
    elseif !has_key(highlighted_lines_map, ctx_id)
      let highlighted_lines_map[ctx_id] = {}
    elseif has_key(highlighted_lines_map[ctx_id], linenr)
      let line += 1
      continue
    endif

    let begin = match(text, exp, max([strlen(linenr), 3]) + 2)
    if begin < 0 | let line += 1 | continue | endif
    let matchend = matchend(text, exp, begin)

    call nvim_buf_add_highlight(0, a:esearch.matches_ns, 'esearchMatch', line - 1, begin, matchend)
    let highlighted_lines_map[ctx_id][linenr] = 1
    let line += 1
  endfor
endfu
