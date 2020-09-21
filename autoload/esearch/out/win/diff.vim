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
        call add(edits[lnum-1], {'func': 'appendline', 'args': [lnum-1, text], 'wlnum': self.wlnum - 1, 'lnum': lnum, 'type': '^'})
        let self.stats.added += 1
      elseif sign ==# '+'
        if !has_key(edits, lnum) | let edits[lnum] = [] | endif
        call add(edits[lnum], {'func': 'appendline', 'args': [lnum, text], 'wlnum': self.wlnum - 1, 'lnum': lnum, 'type': '+'})
        let self.stats.added += 1
      elseif sign ==# '_'
        if !has_key(edits, 0) | let edits[0] = [] | endif
        call add(edits[0], {'func': 'setline', 'args': [1, text], 'wlnum': self.wlnum, 'lnum': 1, 'first': 1})
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
  let edits = s:flatten(a:edits, a:lnums_b)
  let offsets = s:offsets(edits, a:lnums_b)
  let undo = s:undo_edits(edits, a:ctx.lines, a:ctx, offsets, a:ctx.begin + 1, a:lnums_b)
  let a:ctx.begin = a:begin - 1 " TODO side effect
  return {
        \ 'ctx': a:ctx,
        \ 'edits': edits,
        \ 'begin': a:begin,
        \ 'end': a:end,
        \ 'lnums': a:lnums_b,
        \ 'offsets': offsets,
        \ 'undo': undo,
        \}
endfu

fu! s:undo_edits(edits, lines_a, ctx, offsets, begin, lnums_b) abort
  let align = max([3, len(max(keys(a:lines_a)))])
  let fmt = ' %s %'.align.'d '
  let [lines_a, lnums_a, lnums_b] =  [a:lines_a, sort(keys(a:ctx.lines), 'N'), a:lnums_b]
  let [lines, lnum] = [[], []]
  let [offset, a, b] = [0, 0, 0]

  while a < len(lnums_a) && b < len(lnums_b)
    if lnums_a[a] ==# lnums_b[b]
      call add(lnum, lnums_a[a] + offset)
      call add(lines, printf(fmt, ' ', lnum[-1]).lines_a[lnums_a[a]])
      let [a, b] = [a + 1, b + 1]
    elseif +lnums_a[a] < +lnums_b[b]
      while a < len(lnums_a) && +lnums_a[a] < +lnums_b[b]
        call add(lnum, lnums_a[a] + offset)
        call add(lines, printf(fmt, '^', lnum[-1]).lines_a[lnums_a[a]])
        let [offset, a] = [offset - 1, a + 1]
      endw
      let b += 1
    else
      call add(lnum, lnums_a[a] + offset)
      call add(lines, printf(fmt, '^', lnum[-1]).lines_a[lnums_a[a]])
      while b < len(lnums_b) && +lnums_a[a] > +lnums_b[b]
        let b += 1
      endw
      let [offset, a] = [offset - 1, a + 1]
    endif
  endw

  while a < len(lnums_a)
    call add(lnum, lnums_a[a] + offset)
    call add(lines, printf(fmt, '^', lnum[-1]).lines_a[lnums_a[a]])
    let [offset, a] = [offset - 1, a + 1]
  endw

  return [{'func': 'setline', 'args': [a:begin, lines], 'lnum': lnum}]
endfu

" List to apply to line numbers after writing changes
fu! s:offsets(edits, lnums_b) abort
  let [edits, lnums_b] = [a:edits, a:lnums_b]
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

fu! s:flatten(edits, lnums_b) abort
  let edits = []

  for lnum in sort(keys(a:edits), 'N')
    let edits += a:edits[lnum]
  endfor

  let offset = 0
  let e = 0
  while e < len(edits)
    if edits[e].func ==# 'appendline'
      let edits[e].orig = edits[e].args[0]
      let edits[e].args[0] += offset
      let offset += 1
      let e += 1
    elseif edits[e].func ==# 'deleteline'
      let cnt = 0
      while e < len(edits) && edits[e].func ==# 'deleteline'
      let edits[e].orig = edits[e].args[0]
        let edits[e].args[0] += offset - cnt
        let e += 1
        let cnt += 1
      endwhile

      let offset = offset - cnt
    else
      let edits[e].orig = edits[e].args[0]
      let edits[e].args[0] += offset
      if get(edits[e], 'first') | let offset += 1 | endif
      let e += 1
    endif
  endwhile

  return edits
endfu

fu! s:reverse_flatten(edits) abort
  let edits = []

  for lnum in reverse(sort(keys(a:edits), 'N'))
    let edits += reverse(a:edits[lnum])
  endfor

  return edits
endfu

fu! s:err(fmt, wlnum) abort
  return 'DiffError:' . printf(a:fmt, a:wlnum)
endfu
