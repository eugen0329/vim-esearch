fu! esearch#out#win#modifiable#init() abort
  let b:esearch.modifiable = 1
  setlocal modifiable undolevels=1000 noautoindent nosmartindent formatoptions= noswapfile nomodified

  setl buftype=acwrite
  aug esearch_win_modifiable
    au! * <buffer>
    au BufWriteCmd <buffer> call s:write_cmd()
    au TextChanged,TextChangedI,TextChangedP <buffer> call s:text_changed()
  aug END
  let b:esearch.undotree = esearch#undotree#new({
        \ 'ctx_ids_map': b:esearch.ctx_ids_map,
        \ 'line_numbers_map': b:esearch.line_numbers_map,
        \})

  call esearch#compat#visual_multi#init()
endfu

fu! esearch#out#win#modifiable#uninit(esearch) abort
  aug esearch_win_modifiable
    au! * <buffer>
  aug END
endfu

fu! s:text_changed() abort
  if has_key(b:esearch.undotree.nodes, changenr())
    call b:esearch.undotree.checkout(changenr())
  endif

  let state = b:esearch.undotree.head.state
  let delta = len(state.line_numbers_map) - (line('$') + 1)
  if delta == 0 | return | endif

  if delta < 0
    let state = deepcopy(state)
    let state.line_numbers_map += repeat([state.ctx_ids_map[-1]], -delta)
    let state.ctx_ids_map += repeat([state.ctx_ids_map[-1]], -delta)
  elseif delta > 0
    let state = deepcopy(state)
    call remove(state.line_numbers_map, -delta, -1)
    call remove(state.ctx_ids_map, -delta, -1)
  endif

  call b:esearch.undotree.synchronize(state)
endfu

fu! s:write_cmd() abort
  let parsed = esearch#out#win#parse#entire()
  if has_key(parsed, 'error') | throw parsed.error | endif

  let diff = esearch#out#win#diff#do(parsed.contexts, b:esearch.contexts[1:])
  if diff.statistics.files == 0 | echo 'Nothing to save' | return | endi

  let [kinds, total_changes] = [[], diff.statistics.modified + diff.statistics.deleted]
  if diff.statistics.modified > 0 |
    let kinds += [diff.statistics.modified . ' modified']
  endif
  if diff.statistics.deleted > 0
    let kinds += [diff.statistics.deleted . ' deleted']
  endif
  let message = printf('Write changes? (%s %s in %d %s)',
        \ join(kinds, ', '),
        \ total_changes == 1 ? 'line' : 'lines',
        \ diff.statistics.files,
        \ diff.statistics.files == 1 ? 'file' : 'files')
  if esearch#ui#confirm#show(message, ['Yes', 'No']) != 1 | return |endif

  call esearch#writer#do(diff, b:esearch, v:cmdbang)
endfu

fu! esearch#out#win#modifiable#i_CR() abort
  return ''
endfu

fu! esearch#out#win#modifiable#c(type) abort
  return s:delete_region(a:type, 'c')
endfu

fu! esearch#out#win#modifiable#d(type) abort
  return s:delete_region(a:type, 'd')
endfu

fu! s:delete_region(type, key) abort
  let [begin, end] = esearch#util#region_pos(esearch#util#type2region(a:type))
  let [line1, col1] = begin
  let [line2, col2] = end

  let options = esearch#let#restorable({'@@': '', '&selection': 'inclusive'})
  try
    if esearch#util#is_visual(a:type)
      silent exe 'normal! gv'.a:key
    elseif a:type ==# 'line'
      silent exe "normal! '[V']".a:key
    else
      silent exe 'normal! `[v`]'.a:key
    endif

    let state = deepcopy(b:esearch.undotree.head.state)
    if esearch#util#is_linewise(a:type)
      call remove(state.line_numbers_map, line1, line2)
      call remove(state.ctx_ids_map, line1, line2)
    elseif esearch#util#is_charwise(a:type) && line1 < line2
      call remove(state.line_numbers_map, line1 + 1, line2)
      call remove(state.ctx_ids_map, line1 + 1, line2)
    endif
  finally
    call b:esearch.undotree.synchronize(state)
    " call esearch#changes#unlock()
    call options.restore()
  endtry
endfu
