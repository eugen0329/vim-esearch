" idea from incsearch.vim
nnoremap <silent><plug>(-esearch-enable-hlsearch) :<c-u>let &hlsearch = &hlsearch<cr>

fu! esearch#out#win#appearance#matches#init(es) abort
  let a:es.hl_strategy = ''
  if !has_key(a:es.pattern, 'vim') | retu esearch#out#win#appearance#matches#uninit(get(b:, 'esearch', {})) | en

  let a:es.pattern.hl_match = esearch#out#win#matches#pattern_each(a:es)

  if a:es.win_matches_highlight_strategy is# 'viewport'
    let a:es.hl_strategy = 'viewport'
    if g:esearch#has#nvim_lua_regex
      aug esearch_win_hl_matches
        au! * <buffer>
        au CursorMoved <buffer> call luaeval('esearch.deferred_highlight_viewport(_A)', +expand('<abuf>'))
      aug END
    else
      let a:es.last_hl_range = [0,0]
      let a:es.matches_ns = luaeval('esearch.MATCHES_NS')
      let a:es.highlighted_lines = {}
      let l:Callback = function('s:hl_viewport_cb', [a:es])
      let a:es.hl_matches = esearch#async#debounce(Callback, a:es.win_matches_highlight_debounce_wait)
      aug esearch_win_hl_matches
        au! * <buffer>
        au CursorMoved <buffer> call b:esearch.hl_matches.apply()
      aug END
      call luaeval('esearch.buf_attach_matches()')
    endif
    retu
  endif

  if a:es.win_matches_highlight_strategy is# 'hlsearch'
    let a:es.hl_strategy = 'hlsearch'
    let @/ = a:es.pattern.hl_match . '\%>1l'
    if a:es.live_update
      exe "norm \<plug>(-esearch-enable-hlsearch)"
    else
      call feedkeys("\<plug>(-esearch-enable-hlsearch)")
    endif
    retu
  endif

  if a:es.win_matches_highlight_strategy is# 'matchadd'
    let a:es.hl_strategy = 'matchadd'
    let a:es.matches_hl_id = matchadd('esearchMatch', a:es.pattern.hl_match . '\%>1l', -1)
    retu
  endif
endfu

fu! esearch#out#win#appearance#matches#uninit(es) abort
  if has_key(a:es, 'hl_matches')
    aug esearch_win_hl_matches
      au! * <buffer>
    aug END
    call a:es.hl_matches.cancel()
  elsei has_key(a:es, 'matches_hl_id')
    call esearch#util#safe_matchdelete(a:es.matches_hl_id)
  endif
endfu

fu! esearch#out#win#appearance#matches#init_live_updated(es) abort
  if a:es.win_matches_highlight_strategy is# 'hlsearch'
    call feedkeys("\<plug>(-esearch-enable-hlsearch)")
  endif
endfu

fu! esearch#out#win#appearance#matches#soft_stop(es) abort
  call esearch#out#win#appearance#matches#uninit(a:es)
endfu

if g:esearch#has#nvim_lua_regex
  fu! esearch#out#win#appearance#matches#hl_viewport(es) abort
    if get(a:es, 'hl_strategy') is# 'viewport'
      call luaeval('esearch.highlight_viewport()')
    endif
  endf
else
  fu! esearch#out#win#appearance#matches#hl_viewport(es) abort
    if get(a:es, 'hl_strategy') is# 'viewport'
      cal s:hl(a:es, line('w0'), line('w$'))
    endif
  endf
endif

fu! s:hl_viewport_cb(es) abort
  if !a:es.is_current() | retu | en

  let [from, to] = [line('w0'), line('w$')]
  let last_hl_range = a:es.last_hl_range
  if last_hl_range[0] <= from && to <= last_hl_range[1] | retu | en

  let from = esearch#util#clip(from - a:es.win_viewport_off_screen_margin, 1, line('$'))
  let to   = esearch#util#clip(to + a:es.win_viewport_off_screen_margin, 1, line('$'))
  cal s:hl(a:es, from, to)
endf

fu! s:hl(esearch, from, to) abort
  let pattern = a:esearch.pattern.vim
  let state = a:esearch.state
  let state = state
  let done = a:esearch.highlighted_lines
  let a:esearch.last_hl_range = [a:from, a:to]

  let wlnum = a:from
  for text in nvim_buf_get_lines(0, wlnum - 1, a:to, 0)
    let offset = matchend(text, g:esearch#out#win#column_re)
    if offset ==# -1
      let wlnum += 1
      continue
    endif

    let linenr = text[:offset]
    let id = state[wlnum]
    if !has_key(done, id)
      let done[id] = {}
    elseif has_key(done[id], linenr)
      let wlnum += 1
      continue
    endif

    let col_from = match(text, pattern, offset)
    if col_from < 0 | let wlnum += 1 | continue | endif
    let col_to = matchend(text, pattern, col_from)

    call nvim_buf_add_highlight(0, a:esearch.matches_ns, 'esearchMatch', wlnum - 1, col_from, col_to)
    let done[id][linenr] = 1
    let wlnum += 1
  endfor
endf
