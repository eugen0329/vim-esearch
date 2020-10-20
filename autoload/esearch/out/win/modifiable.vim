let s:Log = esearch#log#import()
let s:Undotree = esearch#undotree#import()

fu! esearch#out#win#modifiable#init() abort
  let b:esearch.modifiable = 1
  setlocal modifiable undolevels=1000 noautoindent nosmartindent formatoptions= noswapfile nomodified buftype=acwrite
  aug esearch_win_modifiable
    au! * <buffer>
    au BufWriteCmd <buffer> call s:write_cmd()
    au TextChanged,TextChangedI,TextChangedP <buffer> call s:text_changed()
  aug END
  let b:esearch.undotree = s:Undotree.new(b:esearch.state)
  call esearch#compat#visual_multi#init()
endfu

fu! esearch#out#win#modifiable#uninit(esearch) abort
  aug esearch_win_modifiable
    au! * <buffer>
  aug END
endfu

let g:esearch#out#win#modifiable#delete = []
fu! s:text_changed() abort
  if b:esearch.undotree.has(changenr())
    let b:esearch.state = b:esearch.undotree.checkout(changenr())
    return
  endif

  let state = b:esearch.state
  let delta = len(state) - (line('$') + 1)
  if delta != 0
    let state = copy(state)
    if !empty(g:esearch#out#win#modifiable#delete)
      for wlnum in reverse(sort(g:esearch#out#win#modifiable#delete, 'N'))
        call remove(state, wlnum)
      endfor
      let g:esearch#out#win#modifiable#delete = []
    elseif delta < 0
      call s:Log.warn('esearch: unknown change at line '.getpos("'.")[1].'. See :help esearch-win-editing for details')
      let state += repeat([state[-1]], -delta)
    else
      call s:Log.warn('esearch: unknown change at line '.getpos("'.")[1].'. See :help esearch-win-editing for details')
      call remove(state, -delta, -1)
    endif
  endif

  let b:esearch.state = b:esearch.undotree.commit(state)
endfu

fu! s:write_cmd() abort
  try
    let diff = esearch#out#win#diff#do()
  catch  /^DiffError:/
    exe matchstr(v:exception, 'at line \zs\d\+\ze')
    return s:Log.error(substitute(v:exception, '^DiffError:', '', ''))
  endtry

  if diff.stats.files == 0 | echo 'Nothing to save' | return | endi

  let [kinds, total_changes] = [[], diff.stats.modified + diff.stats.deleted + diff.stats.added]
  if diff.stats.added > 0    | let kinds += [diff.stats.added . ' added']       | endif
  if diff.stats.modified > 0 | let kinds += [diff.stats.modified . ' modified'] | endif
  if diff.stats.deleted > 0  | let kinds += [diff.stats.deleted . ' deleted']   | endif

  let message = printf('Write changes? (%s %s in %d %s)',
        \ join(kinds, ', '), total_changes == 1 ? 'line' : 'lines',
        \ diff.stats.files, diff.stats.files == 1 ? 'file' : 'files')
  if !get(g:, 'esearch_yes') && confirm(message, "&Yes\n&Cancel") != 1 | return |endif

  call esearch#writer#do(diff, b:esearch, v:cmdbang)
endfu

fu! esearch#out#win#modifiable#cr() abort
  let line = line('.')
  let ctx = esearch#out#win#repo#ctx#new(b:esearch, b:esearch.state).by_line(line)
  let align = len(string(max(keys(ctx.lines)))) + 1
  let realign = "\<c-o>:call esearch#out#win#modifiable#align(".ctx.id.','.align.")\<cr>"
  let close_completion_popup = pumvisible() ? "\<c-y>" : ''

  if b:esearch.is_entry()
    let state = copy(b:esearch.state)
    call insert(state, state[line], line+1)
    let b:esearch.state = b:esearch.undotree.commit(state)

    let linenr_and_offset_re = g:esearch#out#win#capture_sign_and_lnum_re.'\(\s'.(&g:autoindent ? '\+' : '').'\)'
    let [sign, linenr, offset] = matchlist(getline('.'), linenr_and_offset_re)[1:3]
    let prefix = printf(' '.(empty(sign) ? '+' : sign).'%'.align.'s', linenr) . offset

    return close_completion_popup."\<cr>".realign.prefix
  endif

  if b:esearch.is_filename()
    let state = copy(b:esearch.state)
    call insert(state, state[line], line+1)
    let b:esearch.state = b:esearch.undotree.commit(state)

    let prefix = printf(' ^%'.align.'s ', '1')

    return close_completion_popup."\<cr>".realign.prefix
  endif

  let state = copy(b:esearch.state)
  call insert(state, state[line], line+1)
  let b:esearch.state = b:esearch.undotree.commit(state)

  return "\<cr>"
endfu

fu! esearch#out#win#modifiable#align(id, align) abort
  let ctx = b:esearch.contexts[a:id]
  let begin = ctx._begin + 1
  let end = esearch#util#clip(ctx._end + 1, begin, line('$'))
  let range = (ctx._begin + 1).','.end
  let pattern = g:esearch#out#win#capture_sign_and_lnum_re
  let replacement = '\=printf(" %s%'.a:align.'s", empty(submatch(1)) ? " " : submatch(1), submatch(2))'

  let cmd = range.'s/'.pattern.'/'.replacement
  let view = winsaveview()
  try
    silent! exe cmd
  finally
    call winrestview(view)
  endtry

  if g:esearch.win_ui_nvim_syntax
    call luaeval('esearch.highlight_ui(_A[1], _A[2], _A[3])', [bufnr(''), begin-1, end-1])
  endif
endfu

fu! esearch#out#win#modifiable#I() abort
  if !b:esearch.is_entry() | return 'I' | endif
  let [line, col] = searchpos(g:esearch#out#win#column_re.'\%'.line('.').'l', 'bce')
  return line . 'gg' . col . '|a'
endfu

fu! esearch#out#win#modifiable#c_dot(wise) abort
  if b:esearch.modifiable
    let options = esearch#let#restorable({'&whichwrap': ''})
    try
      let seq = s:changes_count == 0 ? 'd' : '".p'

      if esearch#util#is_visual(a:wise)
        let cmd = s:delete_visual_cmd(a:wise, s:last_visual, seq)
        let [begin, end] = s:visual2range(s:last_visual)
      else
        let cmd = esearch#operator#cmd(a:wise, seq, s:reg)
        let [begin, end] = s:region(a:wise)
      endif
      let begin[0] += 1

      call s:delete_lines(a:wise, cmd, [begin, end])
    finally
      call options.restore()
    endtry
  endif

  call s:repeat_set()
endfu

fu! esearch#out#win#modifiable#seq(...) abort
  if mode(1) !=# 'n' | return '' | endif

  if a:0
    let s:seq = a:1
    return ''
  endif

  unlet! s:seq
  let [s:original_reg, @"] = [@", '']
  return (empty(s:reg_recording()) ? '' : 'q').'q"'
endfu

fu! esearch#out#win#modifiable#c(wise) abort
  let [s:count, s:reg] = esearch#operator#vars()

  if esearch#util#is_visual(a:wise)
    if !b:esearch.modifiable | return | endif
    let s:repeat_seq = a:wise . "\<plug>(esearch-c.)"
    let s:last_visual = s:save_visual()

    let cmd = esearch#operator#cmd(a:wise, 'd', s:reg)
  else
    if exists('s:seq')
      let seq = s:seq
      unlet s:seq
    else
      norm! q
      let [seq, @"] = [@", s:original_reg]
    endif
    if !b:esearch.modifiable | return | endif

    if seq ==# 'w'
      let s:repeat_seq = "\<plug>(esearch-c.)e"
      let cmd = s:norm('de', s:reg)
    else
      let s:repeat_seq = "\<plug>(esearch-c.)" . seq
      let cmd = esearch#operator#cmd(a:wise, 'd', s:reg)
    endif
  endif

  let [last_line, last_col] = [line('$'), col('$')]
  let [begin, end] = s:region(a:wise)
  let begin[0] += 1
  let [begin, end] = s:delete_lines(a:wise, cmd, [begin, end])

  if esearch#operator#is_linewise(a:wise)
    exe 'norm!' (end[0] == last_line ? 'o' : 'O')
  endif
  exe 'startinsert' . (end[1] + 1 == last_col ? '!' : '')

  let s:changes_count = -b:changedtick
  aug esearch_change
    au InsertLeave * let s:changes_count += b:changedtick | au! esearch_change
  aug END
  call s:repeat_set()
endfu

fu! s:norm(seq, reg) abort
  return 'norm! '
        \ . (empty(s:count) ? '' : s:count)
        \ . (empty(a:reg) ? '' : '"'.a:reg)
        \ . a:seq
endfu

fu! s:repeat_set(...) abort
  call esearch#repeat#set(s:repeat_seq, s:count)
  call esearch#repeat#setreg(s:repeat_seq, s:reg)
endfu

fu! esearch#out#win#modifiable#d_dot(wise) abort
  if b:esearch.modifiable
    let options = esearch#let#restorable({'&whichwrap': ''})
    try
      if esearch#util#is_visual(a:wise)
        let cmd = s:delete_visual_cmd(a:wise, s:last_visual, 'd')
        call s:delete_lines(a:wise, cmd, s:visual2range(s:last_visual))
      else
        call s:delete_lines(a:wise, esearch#operator#cmd(a:wise, 'd', s:reg))
      endif
    finally
      call options.restore()
    endtry
  endif

  call s:repeat_set()
endfu

fu! s:visual2range(last_visual) abort
  return [getcurpos()[1:2], [line('.') + a:last_visual.lnum, col('.') + a:last_visual.col]]
endfu

fu! s:delete_visual_cmd(wise, last_visual, seq) abort
  return 'norm! ' . a:wise
        \ . (a:last_visual.lnum  ? a:last_visual.lnum  . 'j' : '')
        \ . (a:last_visual.col && !esearch#operator#is_linewise(a:wise) ? a:last_visual.col . 'l' : '')
        \ . a:seq
endfu

fu! esearch#out#win#modifiable#d(wise) abort
  if !b:esearch.modifiable | return | endif
  let [s:count, s:reg] = esearch#operator#vars()
  let last_visual = s:save_visual()
  call s:delete_lines(a:wise, esearch#operator#cmd(a:wise, 'd', s:reg))

  if esearch#util#is_visual(a:wise)
    let s:last_visual = last_visual
    let s:repeat_seq =  a:wise . "\<plug>(esearch-d.)"
    call s:repeat_set()
  endif
endfu

fu! s:delete_lines(wise, cmd, ...) abort
  let options = esearch#let#restorable({'&selection': 'inclusive', '@@': ''})
  let state = copy(b:esearch.state)
  try
    let region = empty(get(a:, 1)) ? s:region(a:wise) : a:1

    silent exe a:cmd

    let state = s:delete_region_from_state(a:wise, state, region)
    return region
  finally
    let b:esearch.state = b:esearch.undotree.commit(state)
    call options.restore()
  endtry
endfu

fu! s:delete_region_from_state(wise, state, region) abort
  let [begin, end] = a:region
  let [line1, _col1] = begin
  let [line2, _col2] = end

  if line1 <= line2
    if esearch#operator#is_linewise(a:wise)
      call remove(a:state, line1, line2)
    elseif esearch#operator#is_charwise(a:wise) && line1 < line2
      call remove(a:state, line1 + 1, line2)
    endif
  endif

  return a:state
endfu

fu! s:region(wise) abort
  let view = winsaveview()
  try
    exe esearch#operator#cmd(a:wise, "\<esc>", '_')
    return [getpos("'<")[1:2], getpos("'>")[1:2]]
  finally
    call winrestview(view)
  endtry
endfu

fu! s:save_visual() abort
  return {'lnum': abs(line("'>") - line("'<")), 'col': abs(col("'>") - col("'<"))}
endfu

if g:esearch#has#reg_recording
  let s:reg_recording = function('reg_recording')
else
  fu! s:reg_recording() abort
    return ''
  endfu
endif

fu! esearch#out#win#modifiable#operator() abort
  if v:operator ==# 'g@'
    let operator = matchstr(&operatorfunc, '\v^esearch#out#win#modifiable#\zs[cd]\ze%(_dot)?$')
    if !empty(operator) | return operator | endif
  endif

  return v:operator
endfu
