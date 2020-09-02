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

" idea from incsearch.vim
nnoremap <Plug>(-esearch-enable-hlsearch) :<C-u>let &hlsearch = &hlsearch<CR>

fu! esearch#out#win#appearance#matches#init(es) abort
  if a:es.win_matches_highlight_strategy ==# 'viewport'
    let a:es.last_hl_range = [0,0]
    let a:es.matches_ns = luaeval('esearch.appearance.MATCHES_NS')
    let a:es.lines_with_hl_matches = {}
    let Callback = function('s:hl_viewport_cb', [a:es])
    let a:es.hl_matches = esearch#async#debounce(Callback, a:es.win_matches_highlight_debounce_wait)

    aug esearch_win_hl_matches
      au CursorMoved <buffer> call b:esearch.hl_matches.apply()
    aug to
    call luaeval('esearch.appearance.buf_attach_matches()')
    let a:es.hl_strategy = 'viewport'
    retu
  endif

  if !has_key(a:es.pattern, 'hl_match')
    let a:es.pattern.hl_match = esearch#out#win#matches#pattern_each(a:es)
  endif

  if a:es.win_matches_highlight_strategy ==# 'hlsearch'
    let @/ = a:es.pattern.hl_match
    call feedkeys("\<Plug>(-esearch-enable-hlsearch)")
    let a:es.hl_strategy = 'hlsearch'
    retu
  endif

  if a:es.win_matches_highlight_strategy ==# 'matchadd'
    let a:es.matches_hl_id = matchadd('esearchMatch', a:es.pattern.hl_match, -1)
    let a:es.hl_strategy = 'matchadd'
    retu
  endif

  let a:es.hl_strategy = ''
endfu

fu! esearch#out#win#appearance#matches#uninit(es) abort
  if has_key(a:es, 'hl_matches')
    aug esearch_win_hl_matches
      au! * <buffer>
    aug to
    call a:es.hl_matches.cancel()
  elsei has_key(a:es, 'matches_hl_id')
    call esearch#util#safe_matchdelete(a:es.matches_hl_id)
  endif
endfu

fu! esearch#out#win#appearance#matches#soft_stop(es) abort
  call esearch#out#win#appearance#matches#uninit(a:es)
endfu

fu! esearch#out#win#appearance#matches#hl_viewport(es) abort
  if a:es.hl_strategy ==# 'viewport' | cal s:hl(a:es, line('w0'), line('w$')) | en
endf

fu! s:hl_viewport_cb(es) abort
  if !a:es.is_current() | retu | en

  let [from, to] = [line('w0'), line('w$')]
  let last_hl_range = a:es.last_hl_range
  if last_hl_range[0] <= from && to <= last_hl_range[1] | retu | en

  let from = esearch#util#clip(from - a:es.win_viewport_off_screen_margin, 1, line('$'))
  let to   = esearch#util#clip(to + a:es.win_viewport_off_screen_margin, 1, line('$'))
  cal s:hl(a:es, from, to)
endf

fu! s:hl(es, l1, l2) abort
  let p = a:es.pattern.vim
  let state = esearch#out#win#_state(a:es)
  let lnrs = state.line_numbers_map
  let ids = state.ctx_ids_map
  if len(ids) < a:l2 | retu | en
  let done = a:es.lines_with_hl_matches
  let a:es.last_hl_range = [a:l1,a:l2]

  let l = a:l1
  for txt in nvim_buf_get_lines(0,l-1,a:l2,0)
    let lnr = lnrs[l]
    let i = ids[l]

    if lnr ==# 0 | let l += 1 | con
    elsei !has_key(done,i) | let done[i] = {} |
    elsei has_key(done[i],lnr) | let l += 1 | con | en

    let l1 = match(txt,p,max([strlen(lnr),3]) + 2)
    if l1 < 0 | let l += 1 | con | en
    cal nvim_buf_add_highlight(0,a:es.matches_ns,'esearchMatch',l-1,l1,matchend(txt,p,l1))
    let done[i][lnr] = 1
    let l += 1
  endfo
endf
