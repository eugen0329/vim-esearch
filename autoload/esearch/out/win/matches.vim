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
fu! esearch#out#win#matches#init_highlight(esearch) abort
  if g:esearch_out_win_highlight_matches ==# 'viewport'
    augroup ESearchWinHighlights
      let a:esearch.matches_namespace_id = nvim_create_namespace('esearchMatchesNS')
      au CursorMoved <buffer> let b:esearch.match_highlight_timer = esearch#debounce#trailing(
            \ function('s:highlight_matches_callback', [b:esearch]),
            \ g:esearch_win_matches_highlight_debounce_wait,
            \ b:esearch.match_highlight_timer)
    augroup END
    call luaeval('vim.api.nvim_buf_attach(0, false, {on_lines=update_matches_highlights_cb})')
    let a:esearch.last_hl_range = [0,0]
  elseif g:esearch_out_win_highlight_matches ==# 'matchadd' && has_key(a:esearch.exp, 'vim_match')
    let a:esearch.matches_highlight_id = matchadd('esearchMatch', a:esearch.exp.vim_match, -1)
  endif
endfu

fu! s:highlight_matches_callback(esearch, callback) abort
  let [top, bottom] = [ line('w0'), line('w$') ]
  let last_hl_range = a:esearch.last_hl_range

  if last_hl_range[0] <= top && bottom <= last_hl_range[1]
    return
  endif

  let exp = b:esearch.exp.vim
  let state = esearch#out#win#_state()
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

    call nvim_buf_add_highlight(0, a:esearch.matches_namespace_id, 'esearchMatch', line - 1, begin, matchend)
    let highlighted_lines_map[ctx_id][linenr] = 1
    let line += 1
  endfor
endfu

if !esearch#has#nvim_lua
  finish
endif

lua << EOF
function update_matches_highlights_cb(_, bufnr, ct, from, old_to, to, _old_byte_size)
  if to == old_to then
    local namespace = vim.api.nvim_get_namespaces()['esearchMatchesNS']
    vim.api.nvim_buf_clear_namespace(0, namespace, from, to)
  end
end
EOF
