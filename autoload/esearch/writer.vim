let s:List = vital#esearch#import('Data.List')
let s:Handle = esearch#buf#handle()
let s:by_key = function('esearch#util#by_key')

fu! esearch#writer#do(diffs, esearch, bang) abort
  return s:Writer.new(a:diffs, a:esearch).write(a:bang)
endfu

let s:Writer = {}

fu! s:Writer.new(diffs, esearch) abort dict
  return extend(copy(self), {'diffs': a:diffs, 'esearch': a:esearch})
endfu

fu! s:Writer.write(bang) abort dict
  let cwd = self.esearch.cwd
  let self.conflicts = []
  let WriteCb = self.esearch.write_cb

  let search_buf = s:Handle.new(bufname(''))
  let [current_buffer, current_window] = [esearch#buf#stay(), esearch#win#stay()]
  call esearch#util#doautocmd('User esearch_write_pre')
  let update_win_edits = []
  let lnums_ranges = []
  let undo_edits = []

 " Wipeout preview buffer if was viewed ignoring swap to prevent missing
 " swapexists messages in the future
  call esearch#preview#wipeout()

  aug esearch_write
    au!
    au SwapExists * let v:swapchoice = 'q'
  aug END
  try
    for [id, diff] in sort(items(self.diffs.by_id), s:by_key)
      let path = esearch#out#win#view_data#filename(self.esearch, diff.ctx)
      if !self.verify_readable(diff, path) | continue | endif

      try
        let buf = s:Handle.new(path)
      catch /E325:/ " swapexists exception, will be handled by v:swapchoice set above
        call self.handle_existing_swap(path)
        continue
      endtry
      if !a:bang
        if !self.verify_not_modified(diff, buf) | continue | endif
      endif

      call add(undo_edits, diff.undo)
      let [edit, lnums_range] = self.update_lnums(search_buf, diff)
      call add(update_win_edits, edit)
      call add(lnums_ranges, lnums_range)
      for edit in diff.edits | call call(buf[edit.func], edit.args) | endfor
      if !empty(WriteCb) | call WriteCb(buf, a:bang) | endif
    endfor
  finally
    au! esearch_write
    call current_window.restore()
    call current_buffer.restore()
    call self.squash_undotree(search_buf, update_win_edits, lnums_ranges, undo_edits)
  endtry
  call self.log()
  " Deferring is required to execute the autocommand with avoiding BufWriteCmd side effects
  call esearch#util#try_defer(function('esearch#util#doautocmd'), 'User esearch_write_post')
endfu

fu! s:Writer.squash_undotree(search_buf, update_win_edits, lnums_ranges, undo_edits) abort dict
  let original_register = @s
  try
    call self.update_lines(a:update_win_edits)
    let updated_state = self.update_state(b:esearch.undotree.head.state, a:lnums_ranges)
    silent! %yank s

    call esearch#util#safe_undojoin()
    call self.undo_lines(a:search_buf, a:undo_edits)
    let state = self.undo_state(a:undo_edits)
    call b:esearch.undotree.squash(state)

    call esearch#util#safe_undojoin()
    call esearch#util#squash_undo()

    keepjumps %delete _
    keepjumps %put s
    keepjumps 1delete _

    call b:esearch.undotree.synchronize(updated_state)
  finally
    let @s = original_register
  endtry
endfu

fu! s:Writer.update_lines(update_win_edits) abort
  call map(copy(a:update_win_edits), 'call("setline", v:val)')
endfu

fu! s:Writer.update_state(state, lnums_ranges) abort
  let state = b:esearch.undotree.head.state
  for lnums_range in a:lnums_ranges
    let begin = lnums_range[0]
    let end = begin + len(lnums_range[1]) - 1
    let state.line_numbers_map[begin : end] = lnums_range[1]
  endfor
  return state
endfu

fu! s:Writer.undo_state(undo_edits) abort dict
  let state = deepcopy(b:esearch.undotree.head.state)
  for file_undo in a:undo_edits
    for edit in file_undo
      if edit.func ==# 'deleteline'
        call remove(state.ctx_ids_map, edit.wlnum + 1)
        call remove(state.line_numbers_map, edit.wlnum + 1)
      elseif edit.func ==# 'setline'
        let state.line_numbers_map[edit.wlnum] = edit.lnum
      elseif edit.func ==# 'appendline'
        call insert(state.ctx_ids_map, edit.id, edit.args[0] + 1)
        call insert(state.line_numbers_map, edit.lnum, edit.args[0] + 1)
      else
        throw 'Unknown func: ' . edit.func
      endif
    endfor
  endfor
  return state
endfu

fu! s:Writer.undo_lines(search_buf, undo_edits) abort dict
  for file_undo in reverse(a:undo_edits)
    for edit in file_undo
      call call(a:search_buf[edit.func], edit.args)
    endfor
  endfor
endfu

fu! s:Writer.handle_existing_swap(path) abort dict
  call add(self.conflicts, {'filename': a:path, 'reason': 'swapfile exists'})

  if bufexists(a:path)
    let bufnr = esearch#buf#find(a:path)
    let bufname = simplify(resolve(bufname(bufnr)))
    " Delete ONLY buffer we are loaded to reload swapchoice
    if bufname ==# simplify(resolve(a:path))
      exe bufnr . 'bdelete'
    endif
  endif
endfu

fu! s:Writer.update_lnums(search_buf, diff) abort dict
  let lnums = a:diff.lnums
  let lines = {}
  let offsets = a:diff.offsets
  let align = max([3, len(string(lnums[-1] + offsets[-1]))])

  let wlnum = a:diff.begin
  let lnums_range = [wlnum, []]
  let edit      = [wlnum, []]

  let j = 0
  let end = wlnum + len(lnums)
  while wlnum < end
    let line = a:search_buf.getline(wlnum)
    let new_lnum = offsets[j]+lnums[j]

    let text = matchstr(line, g:esearch#out#win#capture_text_re)
    let linenr = printf(' %'.align.'d ', new_lnum)
    let line = linenr . text

    let lines[new_lnum] = text
    call add(edit[1], line)
    call add(lnums_range[1], new_lnum)
    let wlnum += 1
    let j += 1
  endw

  let b:esearch.contexts[a:diff.ctx.id].lines = lines
  return [edit, lnums_range]
endfu

fu! s:Writer.log() abort dict
  if empty(self.conflicts)
    call esearch#util#warn('Done.')
    return setbufvar(self.esearch.bufnr, '&modified', 0)
  end

  let reasons = map(self.conflicts, 'printf("\n\t%s (%s)", v:val.filename, v:val.reason)')
  let message = "Can't write changes to the following files:".join(reasons, '')
  call esearch#util#warn(message)
endfu

fu! s:Writer.verify_readable(diff, path) abort dict
  if filereadable(a:path) | return 1 | endif
  if get(a:diff.ctx, 'rev')
    call add(self.conflicts, {'filename': a:path, 'reason': 'is a git blob'})
  else
    call add(self.conflicts, {'filename': a:path, 'reason': 'is not readable'})
  endif
  return 0
endfu

fu! s:Writer.verify_not_modified(diff, buf) abort dict
  let ours_lines = a:diff.ctx.lines
  for edit in a:diff.edits
    if !has_key(ours_lines, edit.lnum) || a:buf.getline(edit.lnum) is# ours_lines[edit.lnum]
      continue
    endif

    call add(self.conflicts, {
          \ 'filename': a:diff.ctx.filename,
          \ 'reason':   'line '.edit.lnum.' has changed',
          \})
    return 0
  endfor

  return 1
endfu
