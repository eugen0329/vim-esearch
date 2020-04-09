let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()
let s:separator = ''
let s:linenr_format = ' %3d '

" Handles deletion between line1:col1 and line2:col2.
" Does recovery of virtual ui elements:
"   - header with files and matched lines count
"   - line numbers column (location in a file). Builtin name is LineNr column
"   - file names
"   - context separators

fu! esearch#out#win#delete_multiline#handle(event) abort
  let state = deepcopy(b:esearch.undotree.head.state)
  let contexts = esearch#out#win#repo#ctx#new(b:esearch, state)
  let rebuilder = s:Rebuilder(a:event)
  let line1 = a:event.line1
  let line2 = a:event.line2

  let top_ctx = contexts.by_line(line1)
  if top_ctx.id == 0
    call s:handle_header(top_ctx, rebuilder)
    let top_ctx = top_ctx.end + 1 <= line2 ? contexts.by_line(top_ctx.end + 1) : s:null
  endif

  if rebuilder.col1 > 0 || rebuilder.col2 > 0 || a:event.is_change
    call rebuilder.consume_current_line()
  endif

  if top_ctx isnot# s:null
    let bottom_ctx = contexts.by_line(line2)

    if s:is_across_multiple_contexts(top_ctx, bottom_ctx, rebuilder)
      if a:event.is_change
        if s:is_columnwise_begin(rebuilder)
          call s:handle_top_ctx_columnwise(top_ctx, state, rebuilder)
          call s:handle_top_ctx(top_ctx, state, rebuilder, bottom_ctx)
          call s:handle_bottom_ctx(bottom_ctx, state, rebuilder)
          call s:handle_bottom_ctx_columnwise(bottom_ctx, state, rebuilder)
          call s:handle_columnwise_change_cursor(top_ctx, bottom_ctx, rebuilder, state)
        else
          call s:handle_top_ctx_columnwise(top_ctx, state, rebuilder)
          call s:handle_change(top_ctx, bottom_ctx, rebuilder, state)
          call s:handle_bottom_ctx_columnwise(bottom_ctx, state, rebuilder)
        endif
      else
        call s:handle_ctx_above_top(top_ctx, bottom_ctx, rebuilder, state)
        call s:handle_top_ctx_columnwise(top_ctx, state, rebuilder)
        call s:handle_top_ctx(top_ctx, state, rebuilder, bottom_ctx)
        call s:handle_bottom_ctx(bottom_ctx, state, rebuilder)
        call s:handle_bottom_ctx_columnwise(bottom_ctx, state, rebuilder)
      endif
    else
      if a:event.is_change
        if s:is_columnwise_begin(rebuilder)
          call s:handle_ctx_above_top(top_ctx, bottom_ctx, rebuilder, state)
          call s:handle_columnwise_within_1_ctx(top_ctx, rebuilder, state)
          call s:handle_columnwise_change_cursor(top_ctx, bottom_ctx, rebuilder, state)
        else
          call s:handle_change_within_1_ctx(top_ctx, bottom_ctx, rebuilder, state)
        endif
      else
        call s:handle_ctx_above_top(top_ctx, bottom_ctx, rebuilder, state)
        call s:handle_columnwise_within_1_ctx(top_ctx, rebuilder, state)
      endif
    endif
  endif
  call rebuilder.apply_recovery(state)
  call b:esearch.undotree.synchronize(state)
endfu

fu! s:handle_columnwise_within_1_ctx(ctx, rebuilder, state) abort
  if s:is_all_entries_removed(a:ctx, a:rebuilder, a:state)
    if s:is_orphaned_filename_above(a:ctx, a:rebuilder)
      call a:rebuilder.consume_line_above()
    endif
    if s:is_orphaned_blank_line_below(a:ctx, a:rebuilder, a:state)
      call a:rebuilder.consume_line_below()
    endif
  else
    if s:is_filename_removed(a:ctx, a:rebuilder)
      call a:rebuilder.recover(a:ctx, s:null, a:ctx.filename)
    endif
    call s:handle_columnwise_with_joining_lines(a:ctx, a:state, a:rebuilder)
    if s:is_separator_removed(a:ctx, a:rebuilder, a:state)
          \ && !s:is_until_the_end(a:ctx, a:rebuilder, a:state)
      call a:rebuilder.recover(a:ctx, s:null, s:separator)
    endif
  endif
endfu

fu! s:handle_change_within_1_ctx(top_ctx, bottom_ctx, rebuilder, state) abort
  if s:is_filename_removed(a:bottom_ctx, a:rebuilder)
    call a:rebuilder.recover(a:bottom_ctx, s:null, a:bottom_ctx.filename)
  endif

  if a:rebuilder.line2 < 4
    return
  endif

  if a:rebuilder.line1 != a:rebuilder.line2
       \ || !(a:rebuilder.line1 == a:top_ctx.begin
       \      || (a:rebuilder.line1 == a:top_ctx.end && !s:is_last_context(a:top_ctx, a:state)))
    " If it's not a single-line change or it is and it doesn't affect the UI
    " TODO handle single-line changes outside
    if a:rebuilder.line1 <= a:top_ctx.begin
      let line = a:top_ctx.begin + 1
    else
      let line = a:rebuilder.line1
    endif
    let line_in_file = a:state.line_numbers_map[line]
    let linenr  = printf(s:linenr_format, line_in_file)
    call a:rebuilder.recover(a:top_ctx, line_in_file, linenr)
    let a:rebuilder.cursor = [line, strlen(linenr) + 1]
  endif

  if s:is_separator_removed(a:top_ctx, a:rebuilder, a:state)
    call a:rebuilder.recover(a:top_ctx, s:null, s:separator)
  endif
endfu

fu! s:handle_change(top_ctx, bottom_ctx, rebuilder, state) abort
  if !a:rebuilder.event.is_change
    return
  endif

  if s:is_filename_removed(a:top_ctx, a:rebuilder)
    call a:rebuilder.recover(a:top_ctx, s:null, a:top_ctx.filename)
  endif

  if a:top_ctx.end == a:rebuilder.line1
    let a:rebuilder.cursor = [a:top_ctx.end - 1, 9000]
  else
    if a:rebuilder.line1 <= a:top_ctx.begin + 1
      let line = a:top_ctx.begin + 1
    else
      let line = a:rebuilder.line1
    endif
    let line_in_file = a:state.line_numbers_map[line]
    let linenr  = printf(s:linenr_format, line_in_file)
    call a:rebuilder.recover(a:top_ctx, line_in_file, linenr)
    let a:rebuilder.cursor = [line, strlen(linenr) + 1]
  endif

  if s:is_separator_removed(a:top_ctx, a:rebuilder, a:state)
        \ && !s:is_until_the_end(a:bottom_ctx, a:rebuilder, a:state)
    call a:rebuilder.recover(a:top_ctx, s:null, s:separator)
  endif

  if s:is_all_entries_removed(a:bottom_ctx, a:rebuilder, a:state)
    if s:is_orphaned_blank_line_below(a:bottom_ctx, a:rebuilder, a:state)
      call a:rebuilder.consume_line_below()
    endif
  else
    if s:is_filename_removed(a:bottom_ctx, a:rebuilder)
      call a:rebuilder.recover(a:bottom_ctx, s:null, a:bottom_ctx.filename)
    endif
  endif
endfu

fu! s:handle_columnwise_change_cursor(top_ctx, bottom_ctx, rebuilder, state) abort
  if a:rebuilder.line1 <= a:top_ctx.begin
    let line = a:top_ctx.begin + 1
    let line_in_file = a:state.line_numbers_map[line]
    let linenr  = printf(s:linenr_format, line_in_file)
    let col = strlen(linenr) + 1
  else
    let line = a:rebuilder.line1
    let col = a:rebuilder.col1
  endif

  let a:rebuilder.cursor = [line, col]
endfu

fu! s:handle_ctx_above_top(top_ctx, bottom_ctx, rebuilder, state) abort
  " Handling a context above top_ctx. It's not included in the range,
  " but in some cases we need to cleanup a separator from it to prevent trailing
  " blank lines

  " If it's removal of all contexts until the end, then the line above must be
  " removed to not have trailing lines after the last ctx
  if !s:is_first_context(a:top_ctx, a:state)
        \ && s:is_all_entries_removed(a:top_ctx, a:rebuilder, a:state)
        \ && s:is_until_the_end(a:bottom_ctx, a:rebuilder, a:state)
    " TODO the last condition is not covered with tests
    call a:rebuilder.consume_line_above()
  endif
endfu

fu! s:handle_top_ctx(ctx, state, rebuilder, bottom_ctx) abort
  if s:is_all_entries_removed(a:ctx, a:rebuilder, a:state)
    if s:is_orphaned_filename_above(a:ctx, a:rebuilder)
      call a:rebuilder.consume_line_above()
    endif
  else
    if s:is_separator_removed(a:ctx, a:rebuilder, a:state)
          \ && !s:is_until_the_end(a:bottom_ctx, a:rebuilder, a:state)
      call a:rebuilder.recover(a:ctx, s:null, s:separator)
    endif
  endif
endfu

fu! s:handle_bottom_ctx(ctx, state, rebuilder) abort
  if s:is_all_entries_removed(a:ctx, a:rebuilder, a:state)
    if s:is_orphaned_blank_line_below(a:ctx, a:rebuilder, a:state)
      call a:rebuilder.consume_line_below()
    endif
  else
    if s:is_filename_removed(a:ctx, a:rebuilder)
      call a:rebuilder.recover(a:ctx, s:null, a:ctx.filename)
    endif
  endif
endfu

fu! s:handle_top_ctx_columnwise(ctx, state, rebuilder) abort
  " Lines are joined, recovering the first part
  if s:is_columnwise_begin(a:rebuilder)
        \ && a:rebuilder.line1 != a:ctx.begin
        \ && a:rebuilder.line1 <= a:ctx.end - 1
        \ && !s:is_all_entries_removed(a:ctx, a:rebuilder, a:state)

    let text = getline(a:rebuilder.line1)
    let line_in_file = a:state.line_numbers_map[a:rebuilder.line1]
    let linenr1  = printf(s:linenr_format, line_in_file)
    let recovered = linenr1

    if a:rebuilder.col1 >= 2
      let recovered .= text[strlen(linenr1) : a:rebuilder.col1 - 2]
    endif

    call a:rebuilder.recover(a:ctx, line_in_file, recovered)
  endif
endfu

fu! s:handle_bottom_ctx_columnwise(ctx, state, rebuilder) abort
  if s:is_columnwise_end(a:rebuilder)
        \ && a:ctx.begin + 1 <= a:rebuilder.line2
        \ && !s:is_all_entries_removed(a:ctx, a:rebuilder, a:state)
    " Don't recover if:
    "   - the bottom_ctx is removed
    "   - only the filename is affected

    " When deletion is done across multiple contexts - splitting is required:
    " text before col1 goes to top_ctx, after col1 - to bottom_ctx. Keeping them
    " merged doesn't make sense as these lines are from different files with
    " possibly different filetypes
    let line_in_file   = a:state.line_numbers_map[a:rebuilder.line2]
    let linenr2 = printf(s:linenr_format, line_in_file)
    let text   = getline(a:rebuilder.line1)

    let is_col2_within_linenr = a:rebuilder.col2 < strlen(linenr2) + 1

    if len(getline(a:rebuilder.line1)) + a:rebuilder.col2 == get(a:rebuilder.event, 'lastcol', -1)
      " If columnwise begin
      " TODO reimplement to track if begin and end are columnwise
      " TODO test for removal up from col outside linenr
      let start_idx = (is_col2_within_linenr ? 1 : 0)
    else
      let start_idx = a:rebuilder.col1 - 1
    endif

    if is_col2_within_linenr
      " if the deleted region ends within the virtual interace of the last line - take the
      " part after substring with remained linenr2 chars
      let part2 = text[start_idx + strlen(linenr2) - a:rebuilder.col2 :]
    else " Otherwise if no remaining chars from linenr2 - grab all the remaining text
      let part2 = text[start_idx :]
    endif
    call a:rebuilder.recover(a:ctx, line_in_file, linenr2 . part2)
  endif
endfu

fu! s:handle_columnwise_with_joining_lines(ctx, state, rebuilder) abort
  if a:rebuilder.line2 <= 3 || s:is_all_entries_removed(a:ctx, a:rebuilder, a:state)
    return
  endif

  if s:is_columnwise_end(a:rebuilder)
    let text = getline(a:rebuilder.line1)
    " TODO write more tests for linenr text recovery

    if a:ctx.begin + 1 <= a:rebuilder.line1 " if filename line is not affected:
      " two entries texts are merged within a context and it's required to obtain
      " two parts: remained 1st line text without linenr and remained 2nd line
      " text without possible linenr
      let line_in_file = a:state.line_numbers_map[a:rebuilder.line1]
      let linenr = printf(s:linenr_format, line_in_file)
      let linenr2 = printf(s:linenr_format, a:state.line_numbers_map[a:rebuilder.line2])

      if a:rebuilder.col1 < strlen(linenr) + 1
        " if deletion starts from linenr virtual ui - everything from the
        " first line is removed
        let part1 = linenr
      else
        let part1 = text[: a:rebuilder.col1 - 2]
      endif
      if a:rebuilder.col2 < strlen(linenr2) + 1
        " if the deleted region ends within linenr2 of the last line - take the
        " part after substring with remained linenr2 chars
        let part2 = text[a:rebuilder.col1 - 1 + strlen(linenr2) - a:rebuilder.col2 :]
      else " Otherwise if no remaining chars from linenr2 - grab all the remaining text
        let part2 = text[a:rebuilder.col1 - 1 :]
      endif

      let recovered = part1 . part2
    elseif a:rebuilder.line1 <= 2 " if nothing to merge with (the header is above):
      " TODO consider to combine smh with handling across multiple contexts as
      " the result for the bottom ctx is literally the same
      let line_in_file = a:state.line_numbers_map[a:rebuilder.line2]
      let linenr = printf(s:linenr_format, line_in_file)
      let recovered = linenr[: max([0, a:rebuilder.col2 - 2])] . text[a:rebuilder.col1 - 1 :]
    else " deletion from filename to an entry.
      " Recovering the last affected entry text and line number virtual
      " interface. Filename leftover will be deleted during linewise
      " checks
      let line_in_file = a:state.line_numbers_map[a:rebuilder.line2]
      let linenr = printf(s:linenr_format, line_in_file)
      let recovered = linenr . text[a:rebuilder.col1 - 1 :]
    endif

    call a:rebuilder.recover(a:ctx, line_in_file, recovered)
  elseif s:is_columnwise_begin(a:rebuilder)
        " \ && a:ctx.begin + 1 <= a:rebuilder.line1 " if filename line is not affected:
    let line_in_file  = a:state.line_numbers_map[a:rebuilder.line1]
    let linenr  = printf(s:linenr_format, line_in_file)
    if a:rebuilder.col1 > strlen(linenr) + 1
      let text = getline(a:rebuilder.line1)
      call a:rebuilder.recover(a:ctx, line_in_file, text[: a:rebuilder.col1 - 2])
    endif
  endif
endfu

fu! s:is_filename_removed(ctx, rebuilder) abort
  return a:rebuilder.line1 <= a:ctx.begin
endfu

" A data structure with information to rebuild the interface around deleted
" region. Is made to reduce coupling with the order in which lines and columns
" information is inspected.
fu! s:Rebuilder(event) abort
  let new = {
        \ 'event':                a:event,
        \ 'line1':                a:event.line1,
        \ 'line2':                a:event.line2,
        \ 'col1':                 get(a:event, 'col1', -1),
        \ 'col2':                 get(a:event, 'col2', -1),
        \ 'extended_line1':       a:event.line1,
        \ 'extended_line2':       a:event.line2,
        \ 'delete_lines':         [],
        \ 'add_context_ids':      [],
        \ 'add_line_numbers':     [],
        \ 'add_lines':            [],
        \ 'consume_line_below':   function('s:consume_line_below'),
        \ 'consume_line_above':   function('s:consume_line_above'),
        \ 'consume_current_line': function('s:consume_current_line'),
        \ 'apply_recovery':       function('s:apply_recovery'),
        \ 'recover':              function('s:recover'),
        \ }

  let new.columnwise_top = (new.col1 > 0 ? 1 : 0)
  let new.columnwise_bottom = (new.col2 > 0 ? 1 : 0)
  return new
endfu

fu! s:recover(ctx, line_in_file, text) abort dict
  let self.add_context_ids += [a:ctx.id]
  let self.add_line_numbers += [a:line_in_file]
  let self.add_lines += [a:text]
endfu

fu! s:consume_current_line() abort dict
  let self.delete_lines += [self.extended_line1]
endfu

fu! s:consume_line_above() abort dict
  let self.extended_line1 -= 1
  let self.delete_lines += [self.extended_line1]
endfu

fu! s:consume_line_below() abort dict
  let self.extended_line2 += 1
  let self.delete_lines += [self.extended_line1]
endfu

fu! s:handle_header(header, rebuilder) abort
  if a:rebuilder.line1 == 1
    call a:rebuilder.recover(a:header, s:null, b:esearch.header_text())
  endif

  if a:rebuilder.line1 <= 2 && 2 <= a:rebuilder.line2
    call a:rebuilder.recover(a:header, s:null, s:separator)
  endif
endfu

fu! s:is_orphaned_filename_above(ctx, rebuilder) abort
  return a:rebuilder.line1 ==# a:ctx.begin + 1
endfu

fu! s:is_last_context(ctx, state) abort
  if len(b:esearch.contexts) <= 1 || len(a:state.ctx_ids_map) < 3
    " if all contexts besides header are removed
    return 0
  endif

  return a:ctx.id ==# b:esearch.contexts[a:state.ctx_ids_map[-1]].id
endfu

fu! s:is_first_context(ctx, state) abort
  if len(b:esearch.contexts) <= 1 || len(a:state.ctx_ids_map) < 3
    " if all contexts besides header are removed
    return 0
  endif

  return a:ctx.id ==# b:esearch.contexts[a:state.ctx_ids_map[3]].id
endfu

fu! s:is_separator_removed(ctx, rebuilder, state) abort
  " if it's not trailing (they don't have spearators below) && it was removed
  return !s:is_last_context(a:ctx, a:state) && a:ctx.end <= a:rebuilder.line2
endfu

fu! s:is_until_the_end(bottom_ctx, rebuilder, state) abort
  " TODO test the second condition
  return s:is_last_context(a:bottom_ctx, a:state)
        \ && s:is_all_entries_removed(a:bottom_ctx, a:rebuilder, a:state)
endfu

fu! s:is_orphaned_blank_line_below(ctx, rebuilder, state) abort
  return a:ctx.end != len(a:state.ctx_ids_map) - 1
        \ && a:rebuilder.line2 ==# a:ctx.end - 1
endfu

fu! s:apply_recovery(state) abort dict
  if self.extended_line1 < 1
    let self.extended_line1 = 1
  endif

  call esearch#util#safe_undojoin()

  if !empty(self.delete_lines)
    for line in reverse(sort(self.delete_lines, 'N'))
      call deletebufline(b:esearch.bufnr, line)
    endfor
  endif

  if !empty(self.add_lines)
    if line('$') ==# 1 && empty(getline(1)) " emtpy buffer
      call setline(self.extended_line1, self.add_lines[0])
      call append(self.extended_line1,  self.add_lines[1:])
    else
      call append(self.extended_line1 - 1, self.add_lines)
    endif
  endif

  if g:esearch_out_win_nvim_lua_syntax && self.extended_line1 <= 2
    call luaeval('esearch.highlight.linenrs_range(0,0,1)')
  endif

  call remove(a:state.line_numbers_map, self.extended_line1, self.extended_line2)
  call remove(a:state.ctx_ids_map, self.extended_line1, self.extended_line2)
  call esearch#util#insert(a:state.line_numbers_map, self.add_line_numbers, self.extended_line1)
  call esearch#util#insert(a:state.ctx_ids_map, self.add_context_ids, self.extended_line1)

  if has_key(self, 'cursor')
    call cursor(self.cursor)
    call esearch#changes#rewrite_last_state({
          \ 'size':  line('$'),
          \ 'line': line('.'),
          \ 'col':  col('.'),
          \ })
    if mode() ==# 'i'
      doau CursorMovedI
    else
      doau CursorMoved
    endif
  else
    call esearch#changes#rewrite_last_state({
          \ 'size':  line('$'),
          \ 'line': line('.'),
          \ 'col':  col('.'),
          \ })
  endif
endfu

fu! s:is_across_multiple_contexts(top_ctx, bottom_ctx, rebuilder) abort
  return a:top_ctx != a:bottom_ctx
        \ && a:rebuilder.line1 <= a:top_ctx.end
        \ && a:bottom_ctx.begin <= a:rebuilder.line2
endfu

fu! s:is_columnwise_begin(rebuilder) abort
  return a:rebuilder.col1 > 0
endfu

fu! s:is_columnwise_end(rebuilder) abort
  return a:rebuilder.col2 > 0
endfu

fu! s:is_all_entries_removed(ctx, rebuilder, state) abort
  if a:rebuilder.col1 > 0
    " If columnwise
    " TODO figure out how to fix the side affect (columnwise events alwasy contain col1 > 0)

    " If deletion region is strictly above the first entry
    " or it is on the first entry and col1 is within line numbers virtual ui
    let linenr  = printf(s:linenr_format, a:state.line_numbers_map[a:rebuilder.line1])
    let until_begin = a:rebuilder.line1 <= a:ctx.begin
          \ || a:rebuilder.line1 == a:ctx.begin + 1 && a:rebuilder.col1 <= strlen(linenr) + 1

    " NOTE the last condition can't be matched if virtualedit doesn't contain 'onemore'
    if s:is_last_context(a:ctx, a:state)
      " if the deletion was until the last entry and it's text was deleted entirely
      let until_end = a:ctx.end == a:rebuilder.line2
            \ && strlen(getline(a:rebuilder.line1)) + 1 == a:rebuilder.col1
    else
      " If the deletion region is strictuly below the last entry
      " OR if deletion was until the last entry and it's text was deleted entirely
      let until_end = a:ctx.end  <= a:rebuilder.line2
            \ || (a:ctx.end - 1 == a:rebuilder.line2
            \     && strlen(getline(a:rebuilder.line1)) + 1 == a:rebuilder.col1)
    endif

    return until_begin && until_end
  else
    if a:ctx.begin + 2 <= a:rebuilder.line1
      " If the deletion region starts after the first entry (or at the separator, which
      " also belongs to the contexts) - the context is kept
      return 0
    endif

    if s:is_last_context(a:ctx, a:state)
      return a:ctx.end == a:rebuilder.line2
    else
      return a:ctx.end - 1 <= a:rebuilder.line2
    endif
  endif
endfu
