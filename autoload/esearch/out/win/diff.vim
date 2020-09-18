let s:by_key = function('esearch#util#by_key')

let s:broken_entry_fmt         = 'Unexpected entry format at line %d. Must be " {[+^]?} {line_number} {text}".'
let s:broken_header_fmt        = 'Broken header at line %d.'
let s:unexpected_filename_fmt  = 'Unexpected filename at line %d. Each filename must be preceded with a blank line separator.'
let s:unexpected_prepend_fmt   = 'Unexpected "^" at line %d. Prepended lines must be placed before the base or appended lines.'
let s:unexpected_append_fmt    = 'Unexpected "+" at line %d. Appended lines must be placed after the base line.'
let s:unexpected_lnum_fmt      = 'Unexpected line number at line %d. Line numbers sequence must be increasing.'
let s:missing_filename_fmt     = 'Missing filename before entries at line %d.'
let s:unexpected_separator_fmt = 'Unexpected blank linese parator at line %d.'
let s:unexpected_sign_fmt      = 'Unexpected sign at line %d.'

fu! esearch#out#win#diff#do() abort
  let lines = ['padding'] + getline(1, '$')
  let stats = {
        \ 'deleted':  0,
        \ 'modified': 0,
        \ 'added':    0,
        \ 'files':    0,
        \}
  let diffs = { 'by_id': {}, 'stats': stats}

  let iter = s:DiffIterator.new(lines, b:esearch, stats)

  while iter.has_next()
    let diff = iter.next()

    if !empty(diff.edits)
      let diffs.by_id[diff.ctx.id] = diff
      let stats.files += 1
    endif
  endwhile

  return diffs
endfu

let s:DiffIterator = {
      \ 'wlnum': 3,
      \ 'edits': {},
      \ 'lnum_was': -1,
      \ 'sign_was': '',
      \ 'lines_a': {},
      \ 'begin': -1,
      \ 'ctx': {},
      \ 'deleted_lines_a': {},
      \ 'lnums_b': [],
      \ }

fu! s:DiffIterator.new(lines, esearch, stats) abort dict
  if stridx(a:lines[1], 'Matches in') != 0 | throw s:err(s:broken_header_fmt, 1) | endif
  if !empty(a:lines[2]) | throw s:err(s:broken_header_fmt, 2) | endif

  return extend(copy(self), {
        \ 'lines': a:lines,
        \ 'ctx_ids_map': a:esearch.undotree.head.state.ctx_ids_map,
        \ 'contexts': a:esearch.contexts,
        \ 'stats': a:stats,
        \ })
endfu

fu! s:DiffIterator.has_next() abort dict
  return self.wlnum < len(self.lines)
endfu

" Diff ctx A (ours) and ctx B (theirs)
" line == sign + lnum + text
" wlnum - search window lnum
" edits - script to apply changes in a buffer
" undo - script to revert changes in the search window
fu! s:DiffIterator.next() abort dict
  let [lnum_was, sign_was] = [-1, '']
  let [edits, filename_b, lnums_b] = [{}, '', []]

  while self.wlnum < len(self.lines)
    let line = self.lines[self.wlnum]

    if empty(line)
      if empty(filename_b) | throw s:err(s:unexpected_separator_fmt, self.wlnum) | endif
      let self.wlnum += 1
      return s:Diff.new(self.add_deletes(edits), self.begin, self.wlnum, self.ctx, lnums_b)
    endif

    if line[0] ==# ' '
      if empty(filename_b) | throw s:err(s:missing_filename_fmt, self.wlnum) | endif

      let entry = matchlist(line, g:esearch#out#win#capture_line_re)[1:3]
      if empty(entry) | throw s:err(s:broken_entry_fmt, self.wlnum) | endif

      let [sign, lnum, text] = entry
      if +lnum < +lnum_was | throw s:err(s:unexpected_lnum_fmt, self.wlnum) | endif
      call add(lnums_b, lnum)

      if empty(sign)
        if sign_was ==# '+' && lnum ==# lnum_was | throw s:err(s:unexpected_append_fmt, self.wlnum - 1) | endif

        " if setting an arbitrary line in the file or if the text has changed
        if !has_key(self.lines_a, lnum) || self.lines_a[lnum] !=# text
          if !has_key(edits, lnum) | let edits[lnum] = [] | endif
          call add(edits[lnum], {'func': 'setline', 'args': [lnum, text], 'wlnum': self.wlnum, 'lnum': lnum})
          let self.stats.modified += 1
        endif

        silent! unlet self.deleted_lines_a[lnum]
      elseif sign ==# '^'
        if sign_was ==# '+' || (empty(sign_was) && lnum ==# lnum_was)
          throw s:err(s:unexpected_prepend_fmt, self.wlnum)
        endif

        if !has_key(edits, lnum-1) | let edits[lnum-1] = [] | endif
        call add(edits[lnum-1], {'func': 'appendline', 'args': [lnum-1, text], 'wlnum': self.wlnum - 1, 'lnum': lnum})
        let self.stats.added += 1
      elseif sign ==# '+'
        if !has_key(edits, lnum) | let edits[lnum] = [] | endif
        call add(edits[lnum], {'func': 'appendline', 'args': [lnum, text], 'wlnum': self.wlnum - 1, 'lnum': lnum})
        let self.stats.added += 1
      elseif sign ==# '_'
        if !has_key(edits, lnum) | let edits[lnum] = [] | endif
        call add(edits[lnum], {'func': 'setline', 'args': [lnum, text], 'wlnum': self.wlnum, 'lnum': lnum, 'first': 1})
        let self.stats.added += 1
      else
        throw s:err(s:unexpected_sign_fmt, self.wlnum)
      endif

      let [lnum_was, sign_was] = [lnum, sign]
    else
      let filename_b = line
      let self.ctx = self.contexts[self.ctx_ids_map[self.wlnum]]

      if !empty(self.lines[self.wlnum - 1]) || fnameescape(filename_b) !=# self.ctx.filename
        throw s:err(s:unexpected_filename_fmt, self.wlnum)
      endif

      let self.lines_a = self.ctx.lines
      let self.deleted_lines_a = copy(self.lines_a)
      let self.begin = self.wlnum + 1
    endif

    let self.wlnum += 1
  endwhile

  return s:Diff.new(self.add_deletes(edits), self.begin, self.wlnum - 1, self.ctx, lnums_b)
endfu

fu! s:DiffIterator.add_deletes(edits) abort dict
  if empty(self.deleted_lines_a) | return a:edits | endif

  let [wlnum2offset, offset] = [{}, 0]
  for lnum in sort(keys(self.lines_a), 'N')
    let [wlnum2offset[lnum], offset] = [offset, offset + 1]
  endfor

  for [lnum, text] in sort(items(self.deleted_lines_a), s:by_key)
    if !has_key(a:edits, lnum) | let a:edits[lnum] = [] | endif
    call add(a:edits[lnum], {'func': 'deleteline', 'args': [lnum], 'wlnum': self.begin + wlnum2offset[lnum], 'lnum': lnum})
    let self.stats.deleted += 1
  endfor

  return a:edits
endfu

let s:Diff = {}

fu! s:Diff.new(edits, begin, end, ctx, lnums_b) abort
  if empty(a:edits) | return {'edits': []} | endif
  let edits = s:flatten(a:edits)
  let offsets = s:offsets(edits, a:lnums_b)
  let undo_edits = s:undo_edits(edits, a:ctx.lines, a:ctx, offsets, a:begin, a:lnums_b)
  return {
        \ 'ctx': a:ctx,
        \ 'edits': edits,
        \ 'begin': a:begin,
        \ 'end': a:end,
        \ 'lnums': a:lnums_b,
        \ 'offsets': offsets,
        \ 'undo': undo_edits
        \}
endfu

fu! s:undo_edits(edits, lines_a, ctx, offsets, begin, lnums_b) abort
  let [begin, lines_a, lnums_b] = [a:begin, a:lines_a, a:lnums_b]
  let [offset, lnum_offset] = [0, 0]
  let align = max([3, len(max(keys(lines_a)))])

  let [undo, l] = [[], 0]
  for edit in reverse(copy(a:edits))
    let wlnum = edit.wlnum
    " fastforward to the next affected line
    while l < len(lnums_b) && +lnums_b[l] <= +edit.lnum | let l += 1 | endwhile

    if edit.func ==# 'deleteline'
      let lnum = edit.lnum  - lnum_offset
      let line = printf(' ^%'.align.'d ', lnum) . lines_a[edit.lnum]
      call add(undo, {'func': 'appendline', 'args': [wlnum - 1 + offset, line], 'lnum': lnum, 'wlnum': wlnum, 'id': a:ctx.id})
      let offset -= 1
      let lnum_offset += 1
    elseif edit.func ==# 'appendline'
      call add(undo, {'func': 'deleteline', 'args': [wlnum + 1], 'wlnum': wlnum})
      let offset += 1
      if l < len(lnums_b) && edit.args[0] < lnums_b[l]
        let lnum_offset -= 1
      endif
    elseif edit.func ==# 'setline'
      if get(edit, 'first')
        call add(undo, {'func': 'deleteline', 'args': [wlnum], 'wlnum': wlnum - 1})
      else
        let lnum = edit.lnum + a:offsets[wlnum - begin]
        let line = printf(' %'.align.'d ', lnum) . lines_a[edit.lnum]
        call add(undo, {'func': 'setline', 'args': [wlnum, line], 'lnum': lnum, 'wlnum': wlnum})
      endif
    endif
  endfor

  return reverse(undo)
endfu

" List to apply to line numbers after writing changes
fu! s:offsets(edits, lnums_b) abort
  let [edits, lnums_b] = [reverse(copy(a:edits)), a:lnums_b]
  let [offsets, offset, e, l] = [[], 0, 0, 0]

  while l < len(lnums_b)
    while e < len(edits) && l < len(lnums_b) && +edits[e].lnum <= +lnums_b[l]
      if edits[e].func ==# 'deleteline'
        let offset -= 1
      elseif edits[e].func ==# 'appendline' || get(edits[e], 'first')
        call add(offsets, offset)
        let offset += 1
        let l += 1
      endif
      let  e += 1
    endwhile

    call add(offsets, offset)
    let l += 1
  endwhile

  return offsets
endfu

fu! s:flatten(edits) abort
  let edits = []

  for lnum in reverse(sort(keys(a:edits), 'N'))
    let edits += reverse(a:edits[lnum])
  endfor

  return edits
endfu

fu! s:err(fmt, wlnum) abort
  return 'DiffError:' . printf(a:fmt, a:wlnum)
endfu
