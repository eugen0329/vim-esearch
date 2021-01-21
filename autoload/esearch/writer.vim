let s:Filepath = vital#esearch#import('System.Filepath')
let s:List = vital#esearch#import('Data.List')
let s:Buf = esearch#buf#import()
let s:by_key = function('esearch#util#by_key')

fu! esearch#writer#do(diffs, esearch, bang) abort
  return s:Writer.new(a:diffs, a:esearch).write(a:bang)
endfu

let s:Writer = {}

fu! s:Writer.new(diffs, esearch) abort dict
  return extend(deepcopy(self), {
        \ 'diffs': a:diffs,
        \ 'esearch': a:esearch,
        \ 'search_buf': s:Buf.for(a:esearch.bufnr),
        \ 'win_edits': [],
        \ 'win_undos': [],
        \ 'conflicts': [],
        \})
endfu

fu! s:Writer.write(bang) abort dict
  let l:WriteCb = self.esearch.write_cb
  let [current_window, current_buffer, view] = [esearch#win#stay(), esearch#buf#stay(), winsaveview()]

  call esearch#util#doautocmd('User esearch_write_pre')
 " Wipeout preview buffer if was viewed ignoring swap to prevent missing
 " swapexists messages later
  call esearch#preview#wipeout()
  aug esearch_write
    au!
    au SwapExists * let v:swapchoice = 'q'
  aug END
  let current_options = esearch#let#restorable({'&bufhidden': 'hide', '&buflisted': 1})
  try
    for [id, diff] in sort(items(self.diffs.by_id), s:by_key)
      let path = esearch#out#win#view_data#filename(self.esearch, diff.ctx)
      if !self.verify_readable(diff, path) | continue | endif

      try
        let buf = s:Buf.new(path)
      catch /E325:/ " swapexists exception, will be handled by v:swapchoice set above
        call self.handle_existing_swap(path)
        continue
      endtry
      if !a:bang
        if !self.verify_not_modified(diff, buf) | continue | endif
      endif

      let self.win_edits   = diff.win_edits + self.win_edits
      let self.win_undos   = self.update_file(buf, diff) + self.win_undos
      let self.esearch.contexts[diff.ctx.id].lines = diff.lines_b
      let self.esearch.contexts[diff.ctx.id].begin = diff.begin

      if !empty(WriteCb) | call WriteCb(buf, a:bang) | endif
    endfor
  finally
    au! esearch_write
    call current_window.restore()
    call current_buffer.restore()
    call self.create_undo_entry()
    call current_options.restore()
    call winrestview(view)
  endtry
  call self.log()
  " Deferring is required to execute the autocommand with avoiding BufWriteCmd side effects
  call esearch#util#try_defer(function('esearch#util#doautocmd'), 'User esearch_write_post')
endfu

fu! s:Writer.create_undo_entry() abort dict
  let original_register = @s
  call self.search_buf.goto()
  try
    call self.update_win(self.win_edits)
    let latest_state = self.esearch.state
    silent! %yank s

    exe 'undo' self.esearch.undotree.written.changenr
    call self.update_win(self.win_undos)
    let undone_state = self.esearch.undotree.written.state
    call self.esearch.undotree.squash(undone_state)
    call esearch#util#squash_undo()
    keepjumps %delete _
    keepjumps %put s
    keepjumps 1delete _

    let b:esearch.state = b:esearch.undotree.commit(latest_state)
    call self.esearch.undotree.on_write()
  finally
    let @s = original_register
  endtry
endfu

fu! s:Writer.update_file(buf, diff) abort
  call a:buf.goto()

  let edits = a:diff.edits
  for edit in edits[:-2]
    call call(a:buf[edit.func], edit.args)
  endfor

  if edits[-1].func ==# 'deleteline' && a:buf.oneliner()
    let a:diff.win_undos[0].args[1][-1] =
          \ substitute(a:diff.win_undos[0].args[1][-1], g:esearch#out#win#capture_sign_re, '_', '')
  endif
  call call(a:buf[edits[-1].func], edits[-1].args)

  return a:diff.win_undos
endfu

fu! s:Writer.update_win(win_edits) abort
  for edit in a:win_edits
    call call(self.search_buf[edit.func], edit.args)
  endfor
endfu

fu! s:Writer.handle_existing_swap(path) abort dict
  call add(self.conflicts, {'filename': a:path, 'reason': 'swapfile exists'})

  " Ensure the buffer is deleted after quitting the swap prompt
  if bufexists(a:path)
    let bufnr = esearch#buf#find(a:path)
    let bufname = s:Filepath.abspath(simplify(resolve(bufname(bufnr))))
    if bufname ==# s:Filepath.abspath(simplify(resolve(a:path)))
      exe bufnr . 'bdelete'
    endif
  endif
endfu

fu! s:Writer.log() abort dict
  if empty(self.conflicts)
    call esearch#util#warn('Done.')
    return setbufvar(self.esearch.bufnr, '&modified', 0)
  end

  let reasons = map(self.conflicts, 'printf("\n  %s (%s)", v:val.filename, v:val.reason)')
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
    if !has_key(ours_lines, edit.args[0]) || a:buf.getline(edit.args[0]) is# ours_lines[edit.args[0]]
      continue
    endif

    call add(self.conflicts, {
          \ 'filename': a:diff.ctx.filename,
          \ 'reason':   'line '.edit.args[0].' has changed',
          \})
    return 0
  endfor

  return 1
endfu
