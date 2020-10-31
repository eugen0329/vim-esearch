let s:Dict   = vital#esearch#import('Data.Dict')
let s:by_key = function('esearch#util#by_key')

let s:broken_entry_fmt         = 'Unexpected entry format at line %d. Must match /^ (sign)? (line_number) (text)/.'
let s:broken_header_fmt        = 'Broken header at line %d.'
let s:unexpected_filename_fmt  = 'Unexpected filename at line %d. Each filename must be preceded with a blank line separator.'
let s:unexpected_prepend_fmt   = 'Unexpected "^" at line %d. Prepended lines must be placed before the base or appended lines.'
let s:unexpected_append_fmt    = 'Unexpected "+" at line %d. Appended lines must be placed after the base line.'
let s:duplicate_set_fmt        = 'Duplicate line number at line %d.'
let s:unexpected_set_fmt       = "Unexpected line number at line %d. Can't set an arbitrary line in the file."
let s:unexpected_lnum_fmt      = 'Unexpected line number at line %d. Line numbers sequence must be increasing.'
let s:missing_filename_fmt     = 'Missing filename before entries at line %d.'
let s:unexpected_separator_fmt = 'Unexpected blank line parator at line %d.'
let s:unexpected_sign_fmt      = 'Unexpected sign at line %d.'

fu! esearch#out#win#diff#do() abort
  let stats = {'deleted':  0, 'modified': 0, 'added': 0, 'files': 0}
  let diffs = {'by_id': {}, 'stats': stats}
  let iter = s:DiffsIterator.new(getline(1, '$'), b:esearch, stats)
  while iter.has_next()
    let diff = iter.next()

    if !empty(diff.edits)
      let diffs.by_id[diff.ctx.id] = diff
      let stats.files += 1
    endif
  endwhile

  return diffs
endfu

let s:DiffsIterator = {'wlnum': 3}

fu! s:DiffsIterator.new(lines, esearch, stats) abort dict
  if a:lines !=# ['']
    if stridx(a:lines[0], 'Matches in') != 0 | throw s:err(s:broken_header_fmt, 1) | endif
    if !empty(get(a:lines, 1)) | throw s:err(s:broken_header_fmt, 2) | endif
  endif

  return extend(copy(self), {
        \ 'lines': ['padding'] + a:lines,
        \ 'state': a:esearch.state,
        \ 'contexts': a:esearch.contexts,
        \ 'stats': a:stats,
        \ 'deleted_ctxs_a': s:Dict.make_index(range(1, len(a:esearch.contexts) - 1)),
        \})
endfu

fu! s:DiffsIterator.has_next() abort dict
  return self.wlnum < len(self.lines) || !empty(self.deleted_ctxs_a)
endfu

" Diff each ctx A (ours) and ctx B (theirs).
" line := sign + lnum + text
" wlnum - search window lnum
" edits - script to apply changes in a buffer
" undo - script to revert changes in the search window
fu! s:DiffsIterator.next() abort dict
  if self.wlnum < len(self.lines) | return self.next_modified() | endif
  return self.next_deleted()
endfu

fu! s:DiffsIterator.next_deleted() abort dict
  if !has_key(self, 'sorted_deleted_ctxs_a')
    let self.sorted_deleted_ctxs_a = sort(keys(self.deleted_ctxs_a), 'N')
  endif

  let id = remove(self.sorted_deleted_ctxs_a, 0)
  call remove(self.deleted_ctxs_a, id)
  let ctx = self.contexts[id]
  let [edits, deleted_lines_a] = [{}, copy(ctx.lines)]
  let [begin, lnums_b, texts_b] = [-1, [], []]
  return s:Diff.new(self.add_deletes(edits, deleted_lines_a), begin, ctx, lnums_b, texts_b)
endfu

fu! s:DiffsIterator.next_modified() abort
  let [filename_b, lnum_was, sign_was] = ['', -1, ''] " backtrack one line back
  let [edits, deleted_lines_a, begin, lnums_b, texts_b] = [{}, {}, -1, [], []]

  while self.wlnum < len(self.lines)
    let line = self.lines[self.wlnum]

    if empty(line)
      if empty(filename_b) | throw s:err(s:unexpected_separator_fmt, self.wlnum) | endif
      let self.wlnum += 1
      return s:Diff.new(self.add_deletes(edits, deleted_lines_a), begin, ctx, lnums_b, texts_b)
    endif

    if line[0] ==# ' '
      if empty(filename_b) | throw s:err(s:missing_filename_fmt, self.wlnum) | endif

      let entry = matchlist(line, g:esearch#out#win#capture_entry_re)[1:3]
      if empty(entry) | throw s:err(s:broken_entry_fmt, self.wlnum) | endif

      let [sign, lnum, text] = entry
      if +lnum < +lnum_was | throw s:err(s:unexpected_lnum_fmt, self.wlnum) | endif
      call add(lnums_b, lnum)
      call add(texts_b, text)

      if empty(sign)
        if sign_was ==# '+' && lnum ==# lnum_was | throw s:err(s:unexpected_append_fmt, self.wlnum - 1) | endif
        if empty(sign_was) && lnum ==# lnum_was | throw s:err(s:duplicate_set_fmt, self.wlnum) | endif
        if !has_key(lines_a, lnum) | throw s:err(s:unexpected_set_fmt, self.wlnum) | endif

        " if setting an arbitrary line in the file or if the text has changed
        if lines_a[lnum] !=# text
          if !has_key(edits, lnum) | let edits[lnum] = [] | endif
          call add(edits[lnum], {'func': 'setline', 'args': [lnum, text], 'lnum': lnum})
          let self.stats.modified += 1
        endif

        silent! unlet deleted_lines_a[lnum]
      else
        if !has_key(edits, lnum) | let edits[lnum] = [] | endif
        let self.stats.added += 1

        if sign ==# '^'
          if sign_was ==# '+' || (empty(sign_was) && lnum ==# lnum_was)
            throw s:err(s:unexpected_prepend_fmt, self.wlnum)
          endif

          call add(edits[lnum], {'func': 'appendline', 'args': [lnum-1, text], 'lnum': lnum})
        elseif sign ==# '+'
          call add(edits[lnum], {'func': 'appendline', 'args': [lnum, text], 'lnum': lnum})
        elseif sign ==# '_'
          call add(edits[lnum], {'func': 'setline', 'args': [lnum, text], 'lnum': 1, 'first': 1})
        else
          throw s:err(s:unexpected_sign_fmt, self.wlnum)
        endif
      endif

      let [lnum_was, sign_was] = [lnum, sign]
    else
      let filename_b = line
      let ctx = self.contexts[self.state[self.wlnum]]
      silent! unlet self.deleted_ctxs_a[ctx.id]

      if !empty(self.lines[self.wlnum - 1]) || filename_b !=# fnameescape(ctx.filename)
        throw s:err(s:unexpected_filename_fmt, self.wlnum)
      endif

      let lines_a = ctx.lines
      let deleted_lines_a = copy(lines_a)
      let begin = self.wlnum
    endif

    let self.wlnum += 1
  endwhile

  return s:Diff.new(self.add_deletes(edits, deleted_lines_a), begin, ctx, lnums_b, texts_b)
endfu

fu! s:DiffsIterator.add_deletes(edits, deleted_lines_a) abort dict
  if empty(a:deleted_lines_a) | return a:edits | endif

  for [lnum, text] in sort(items(a:deleted_lines_a), s:by_key)
    if !has_key(a:edits, lnum) | let a:edits[lnum] = [] | endif
    call add(a:edits[lnum], {'func': 'deleteline', 'args': [lnum], 'lnum': lnum})
    let self.stats.deleted += 1
  endfor

  return a:edits
endfu

let s:Diff = {}

fu! s:Diff.new(edits, begin, ctx, lnums_b, texts_b) abort
  if empty(a:edits) | return {'edits': []} | endif
  let edits = s:reverse_flatten(a:edits)
  let win_undos = s:win_undos(a:ctx.lines, a:ctx, a:ctx.begin, a:lnums_b)
  let [win_edits, lines_b] = s:win_write_post_edits(edits, a:lnums_b, a:texts_b, a:begin)
  return {
        \ 'ctx': a:ctx,
        \ 'edits': edits,
        \ 'win_edits': win_edits,
        \ 'win_undos': win_undos,
        \ 'begin': a:begin,
        \ 'lines_b': lines_b,
        \}
endfu

fu! s:win_write_post_edits(edits, lnums_b, texts_b, begin) abort
  if empty(a:lnums_b) | return [[], {}] | endif

  let [lnums_b, texts_b] = [a:lnums_b, a:texts_b]
  let offsets = s:lnum_offsets(reverse(copy(a:edits)), lnums_b)
  let lnum_fmt = ' %'.max([3, len(string(lnums_b[-1] + offsets[-1]))]).'d '

  let [i, new_win_lines, new_lnums, lines_b] = [0, [], [], {}]
  while i < len(lnums_b)
    let lnum = offsets[i] + lnums_b[i]
    let text = texts_b[i]

    let lines_b[lnum] = text
    call add(new_win_lines, printf(lnum_fmt, lnum) . text)
    call add(new_lnums, lnum)

    let i += 1
  endwhile

  let win_edits =   [{'func': 'setline', 'args': [a:begin + 1, new_win_lines]}]
  return [win_edits, lines_b]
endfu

fu! s:win_undos(lines_a, ctx, begin, lnums_b) abort
  if empty(a:lines_a) | return [] | endif

  let align = max([3, len(max(keys(a:lines_a)))])
  let lnum_fmt = ' %s %'.align.'d '
  let [lines_a, lnums_a, lnums_b] =  [a:lines_a, sort(keys(a:ctx.lines), 'N'), a:lnums_b]
  let [lines, offset, a, b] = [[], 0, 0, 0]

  while a < len(lnums_a) && b < len(lnums_b)
    if lnums_a[a] ==# lnums_b[b]
      call add(lines, printf(lnum_fmt, ' ', lnums_a[a] + offset).lines_a[lnums_a[a]])
      let b += 1
      while b < len(lnums_b) && lnums_a[a] ==# lnums_b[b]
        let [offset, b] = [offset + 1, b + 1]
      endw
      let a += 1
    elseif +lnums_a[a] < +lnums_b[b] " line A is missing in B, it was a deletion
      while a < len(lnums_a) && +lnums_a[a] < +lnums_b[b]
        call add(lines, printf(lnum_fmt, '^', lnums_a[a] + offset).lines_a[lnums_a[a]])
        let [offset, a] = [offset - 1, a + 1]
      endw
    else  " line B is missing above A (^), it was a prepending
      let b = b + 1
      while b < len(lnums_b) && +lnums_a[a] > +lnums_b[b]
        let [offset, b] = [offset + 1, b + 1]
      endw

      if b < len(lnums_b) &&  lnums_a[a] ==# lnums_b[b]
        call add(lines, printf(lnum_fmt, ' ', lnums_a[a] + offset + 1).lines_a[lnums_a[a]])
      else
        call add(lines, printf(lnum_fmt, '^', lnums_a[a] + offset + 1).lines_a[lnums_a[a]])
      endif
      let a = a + 1
    endif
  endw

  while a < len(lnums_a) " last lines from B are missing
    call add(lines, printf(lnum_fmt, '^', lnums_a[a] + offset).lines_a[lnums_a[a]])
    let [offset, a] = [offset - 1, a + 1]
  endw

  return [{'func': 'setline',  'args': [a:begin + 1, lines]}]
endfu

fu! s:lnum_offsets(edits, lnums_b) abort
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
