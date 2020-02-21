let s:Vital   = vital#esearch#new()
let s:String  = s:Vital.import('Data.String')
let s:unknown = -1

fu! esearch#changes#listen_for_current_buffer(...) abort
  let b:__states = []
  let b:__changes = []
  let b:__lines = []
  let b:__incrementable_state_id = 0
  let b:__observer = function('<SID>noop')

  if a:0 > 0
    let b:__undotree = a:1
  else
    let b:__undotree = esearch#undotree#new({})
  endif

  call s:handle_cursor_moved('n')
  call s:handle_cursor_moved('n')

  augroup ESearchChanges
    au! * <buffer>
    au InsertEnter                           <buffer> call s:handle_cursor_moved('i')
    au CursorMoved                           <buffer> call s:handle_cursor_moved('n')
    au CursorMovedI                          <buffer> call s:handle_cursor_moved('i')
    au TextChanged,TextChangedI,TextChangedP <buffer> call s:handle_text_changed()
  augroup END
endfu

" @vimlint(EVL103, 1, a:resolve)
" @vimlint(EVL103, 1, a:reject)
fu! s:noop(event) abort
endfu
" @vimlint(EVL103, 0, a:resolve)
" @vimlint(EVL103, 0, a:reject)

fu! esearch#changes#unlisten_for_current_buffer() abort
  augroup ESearchChanges
    au! * <buffer>
  augroup END
endfu

fu! esearch#changes#rewrite_last_state(attributes) abort
  call extend(b:__states[-1], a:attributes, 'force')
endfu

fu! esearch#changes#undo_state() abort
  if !empty(b:__states) && !empty(b:__changes) && b:__states[-1].id != b:__changes[-1].sid
    call remove(b:__states, -1)
  endif
endfu

fu! s:payload() abort
  let b:__incrementable_state_id += 1
  return {
        \ 'id':           b:__incrementable_state_id,
        \ 'mode':         mode(),
        \ 'line':         line('.'),
        \ 'col':          col('.'),
        \ 'lastcol':      col('$'),
        \ 'size':         line('$'),
        \ 'selection1':   getpos("'<")[1:2],
        \ 'selection2':   getpos("'>")[1:2],
        \ 'current_line': getline(line('.')),
        \ 'next_line':    getline(line('.')+1),
        \ 'changenr':     changenr(),
        \ }
endfu

fu! s:handle_cursor_moved(mode) abort
  let payload =  s:payload()
  if a:mode ==# 'i'
    let payload.mode = a:mode
  endif

  call add(b:__states, payload)
  call add(b:__lines, getline(1, '$'))
endfu

fu! s:handle_text_changed() abort
  let [from, to] = b:__states[-2:-1]

  if mode() !=# to.mode || to.line != line('.') || to.col != col('.')
    " Missed event
    call s:handle_cursor_moved('n')
  endif

  let undotree = undotree()
  if undotree.seq_last > undotree.seq_cur
        \ || (to.mode !=# 'i'
        \     && has_key(b:__undotree.nodes, changenr())
        \     && from.changenr < to.changenr)
    return s:emit_undotree_traversal()
  elseif from.mode ==# 'i'
    return s:identify_insert()
  elseif from.mode ==# 'V' || to.mode ==# 'V'
    return s:identify_visual_line()
  elseif from.mode ==# 'v'
    return s:identify_visual()
  elseif from.mode ==# 'n'
    return s:identify_normal()
  endif

  return s:emit({'id': 'undefined-mode', 'mode': [from.mode, to.mode]})
endfu

fu! esearch#changes#add_observer(funcref) abort
  let b:__observer = a:funcref
endfu

fu! s:emit(event) abort
  let a:event.sid = b:__states[-1].id
  call b:__observer(a:event)
  call add(b:__changes, a:event)
endfu

fu! s:emit_undotree_traversal() abort
  return s:emit({
        \ 'id': 'undo-traversal',
        \ 'changenr': b:__states[-1].changenr,
        \ })
endfu

fu! s:identify_visual_line() abort
  let [from, to] = b:__states[-2:-1]

  if from.line == to.line
    " CURSOR IS ON THE SAME LINE:
    "   - paste  moving up
    "   - paste  replacing a single line
    "   - delete moving up
    let line1 = to.line

    if from.size > to.size
      " LINES COUNT IS REDUCED:
      "   - reducing paste
      "   - removal

      if to.selection1[0] == to.selection2[0]
        " SELECTION IS COLLAPSED:
        "   - delete
        "   - paste from the last line
        " TODO can be confused with pasting with \n
        " thus if to.current_line != from.getline(line2+1) - it's paste

        if empty(to.current_line) && to.size == 1
          " deleting all lines
          let line2 = line1 + from.size - to.size
        else
          let line2 = line1 + from.size - to.size - 1
        endif

        " LINES DIRTY CHECK
        if (empty(to.current_line) && to.size == 1) || b:__lines[-2][line2] == to.current_line
          return s:emit({
                \ 'id':     'V-line-delete-up1',
                \ 'line1':  line1,
                \ 'line2':  line2,
                \ })
        endif
        let line2 = line1 + from.size - to.size + to.selection2[0] - to.selection1[0]

        if s:is_joining(from, to, line1, line2)
          return s:emit({
                \ 'id':    'V-join3',
                \ 'line1':    line1,
                \ 'line2':    line2,
                \ })
        else
          return s:emit({
                \ 'id':    'V-line-reducing-paste-up1',
                \ 'line1':    line1,
                \ 'line2':    line2,
                \ })
        endif
      else
        let line2 = line1 + from.size - to.size + to.selection2[0] - to.selection1[0] - 1
        if s:is_joining(from, to, line1, line2)
          return s:emit({
                \ 'id':    'V-join4',
                \ 'line1':    line1,
                \ 'line2':    line2,
                \ })
        else
          return s:emit({
                \ 'id':    'V-line-reducing-paste-up2',
                \ 'line1':    line1,
                \ 'line2':    line2,
                \ })
        endif
      endif

    elseif from.size == to.size
      " LINES COUNT IS KEPT:
      "   - paste

      if to.selection1[0] == to.selection2[0]
        " COLLAPSED SELECTION:
        "   - inline paste
        "   - paste from the last line
        return s:emit({
              \ 'id':    'V-line-paste-up',
              \ 'line1': from.line,
              \ 'line2': s:unknown,
              \ })
      else
        return s:emit({
              \ 'id':    'V-line-paste-up',
              \ 'line1': from.line,
              \ 'line2': max([to.selection1[0], to.selection2[0]]),
              \ })
      endif
    else
      " LINES SIZE INCERASED:
      "   - extending paste
      if to.selection1[0] == to.selection2[0] || (to.selection2[0] - to.selection1[0]) == (to.size - from.size)
        " SELECTION IS COLLAPSED OR EXPANDED EXACTLY TO THE COUNT OF LINES:
        "   - one line paste
        return s:emit({
              \ 'id': 'V-line-extending-paste-up',
              \ 'line1': to.line,
              \ 'line2': to.line,
              \ })
      else
        " to.selection2 cannot be used as it's different in vim/neovim
        return s:emit({
              \ 'id':    'V-line-extending-paste-up',
              \ 'line1': to.line,
              \ 'line2': to.line + (to.size - from.size),
              \ })
      endif
    endif

  elseif from.line > to.line
    " CURSOR JUMPS UP:
    "   - paste moving down
    "   - delete moving down

    if abs(from.size - to.size) - 1 == abs(from.line - to.line)
      let line1 = to.selection1[0]
      let line2  = from.line

      if to.line == to.size
        let line2  = line1 + from.size - to.size - 1
      endif

      return s:emit({
            \ 'id': 'V-line-delete-down',
            \ 'line1': line1,
            \ 'line2': line2,
            \ })
    elseif to.size == to.line
      " CURSOR IS ON THE LAST LINE:
      "   - delete moving down to $
      "   - delete moving up from $
      "   - joining all lines

      let line2 = from.size
      if to.size == 1 && empty(to.current_line)
        " delete all lines
        let line1 = 1
      else
        let line1 = to.line + 1
      endif

      if s:is_joining(from, to, line1, line2)
        return s:emit({
              \ 'id':    'V-join1',
              \ 'line1': line1,
              \ 'line2': line2,
              \ })
      else
        return s:emit({
              \ 'id':    'V-line-delete-up2',
              \ 'line1': line1,
              \ 'line2': line2,
              \ })
      endif
    elseif from.size == to.size
      " LINES COUNT IS KEPT:
      "   - replacing paste
      return s:emit({
            \ 'id': 'V-line-paste-down',
            \ 'line1': to.selection1[0],
            \ 'line2': from.line,
            \ })
    elseif from.size > to.size
      " LINES COUNT IS REDUCED:
      "   - reducing paste
      "   - joining

      if s:is_joining(from, to, to.line, from.line)
        return s:emit({
              \ 'id': 'V-join2',
              \ 'line1': to.line,
              \ 'line2': from.line,
              \ })
      else
        return s:emit({
              \ 'id': 'V-line-reducing-paste-down',
              \ 'line1': to.line,
              \ 'line2': from.line,
              \ })
      endif
    else
      " LINES COUNT IS INCREASED:
      "   - extending paste
      return s:emit({
            \ 'id': 'V-line-extending-paste-down',
            \ 'line1': to.line,
            \ 'line2': from.line,
            \ })
    endif
  elseif from.line < to.line
    "   cursor jumps down (but can it be possible without scripts?)
    return s:emit({'id': 'V-unexpected', 'debug': [from,to]})
  endif

  return s:emit({'id': 'undefined-visual-line', 'debug': [from,to]})
endfu

fu! s:identify_normal() abort
  let [from, to] = b:__states[-2:-1]

  " TODO rewrite to compare from-to size first

  if from.line == to.line
    " CURSOR IS ON THE SAME LINE:
    "   - paste  up
    "   - motion down
    "   - inline change

    " motion down or inline
    if from.size > to.size
      " LINES COUNT IS REDUCED:
      "   - removal
      "   - join
      "   - removal with textobject TODO

      let line1 = from.line
      if to.size == 1 && empty(to.current_line)
        " delete all lines
        let line2 = from.size
      elseif to.size == to.line && to.line < from.line
        let line2 = from.size " likely a textobject
      else
        let line2 = line1 + from.size  - (to.size + 1)
      endif

      if s:is_joining(from, to, line1, line2)
        " NOTE when joining empty lines it's equivalent to motion down
        return s:emit({ 'id': 'n-join', 'line1': line1, 'line2': line2})
      elseif from.col == 1 || from.col >= 2 && from.current_line[: from.col - 2 ] == to.current_line[: from.col - 2 ]
        " LINE PREFIXES ARE EQUAL:
        "   - columnwise motion right

        let col2 = s:last_col(from, to, line2 + 1) - 1

        if from.col == 1 && col2 < 1
            return s:emit({
                  \ 'id': 'n-motion-down4',
                  \ 'line1': line1,
                  \ 'line2': line2,
                  \ })

          elseif (&virtualedit ==# 'onemore' && strchars(to.current_line) == to.col - 1)
              \ || (strchars(to.current_line) == to.col && to.col == from.col - 1)
          " IF:
          "   - on the last virtual column
          "   - OR the last column and cursor shifted one column left
          " then the end of deleted region is linewise

            return s:emit({
                  \ 'id': 'n-motion-down-columnwise-right1',
                  \ 'col1':  from.col,
                  \ 'line1': line1,
                  \ 'line2': line2 + 1,
                  \ })
        else
          "   - both side of the region are linewise (clever-f or other motions)
          return s:emit({
                \ 'id': 'n-motion-down-columnwise-right2',
                \ 'col1':  from.col,
                \ 'line1': line1,
                \ 'line2': line2 + 1,
                \ 'col2': col2,
                \ })
                " \ 'debug': [from,to],
        endif
      else
        return s:emit({ 'id': 'n-motion-down2', 'line1': line1, 'line2': line2})
      endif
    elseif from.size == to.size
      " LINES COUNT IS KEPT:
      "   - inline changes
      return s:identify_normal_inline(from,to)
    else
      " LINES COUNT IS INCREASED:
      "   - paste back (with P)
      return s:emit({ 'id': 'n-paste-back', 'line1': to.line, 'line2': to.line + to.size - 1 - from.size })
    endif
  elseif from.line > to.line
    " CURSOR JUMPS UP:
    "   - motion up
    "   - motion down until the last line
    "   - paste down (with p)
    "   - textobject

    " LINES DIRTY CHECK
    if to.current_line == from.next_line
      let line1 = min([from.line, to.line])
      let last  = max([from.line, to.line])

      if from.line == from.size && to.size != 1
        let line1 += 1
      endif

      return s:emit({'id': 'n-motion-up', 'line1': line1, 'line2': last})
    elseif to.size == to.line
      " START AT THE LAST LINE:


      if from.current_line[from.col - 1  : ] == to.current_line[to.col - 1 : ]
        " to.col == 1 ||  from.col >= 2 && 
        " POSTFIXES PREFIXES ARE EQUAL:
        return s:emit({
              \ 'id':    'n-motion-up-columnwise-left2',
              \ 'line1': to.line,
              \ 'line2': from.line,
              \ 'col1':  to.col,
              \ 'col2':  from.col,
              \ })
      else
        if to.size == 1 && empty(to.current_line)

          " delete all lines
          let line1 = 1
        else
          let line1 = to.line + 1
        endif

        return s:emit({'id': 'n-motion-up', 'line1': line1, 'line2': from.size})
      endif
    else
      if from.current_line[from.col - 1  : ] == to.current_line[to.col - 1 : ]
        " to.col == 1 ||  from.col >= 2 && 
        " POSTFIXES ARE EQUAL:
        " - textobject
        " - easymotion jump up TODO
        " - columnwise delete left

        " TODO is not recognized whe deleting from the last line
        " TODO fix hack with lastcol
        return s:emit({
              \ 'id':    'n-motion-up-columnwise-left1',
              \ 'line1': to.line,
              \ 'line2': from.line,
              \ 'col1':  to.col,
              \ 'col2':  from.col,
              \ 'lastcol': from.lastcol,
              \ })
      else
        return s:emit({
              \ 'id': 'n-motion-down3',
              \ 'line1': to.line,
              \ 'line2': to.line + from.size - to.size - 1
              \ })
      endif
    endif
  else " from.line < to.line
    " CURSOR JUMPS DOWN:

    if to.size == from.size
      " unregistered event, caused by calling cursor() using +clientserver
      " probably can be handled via fetching from undo, but as far as
      " CursorMoved is executed always during normal execution it's skipped for
      " now

      " Is also triggered after commandline commands like substitute etc.

      " + easymotion jump down TODO
      return s:emit({
            \ 'id':    'skip?',
            \ 'line1': to.line,
            \ 'line2': to.line,
            \ })
    elseif to.size < from.size
      " unregistered event?
      " LINES COUNT IS REDUCED:
      "   - removal

      let line1 = to.line
      let line2 = to.line

      return s:emit({ 'id': 'n-motion-up4', 'line1': line1, 'line2': line2})
    else
      return s:emit({
            \ 'id':    'n-paste-forward',
            \ 'line1': to.line,
            \ 'line2': to.line + to.size - 1 - from.size
            \ })
    endif
  endif

  return s:emit({'id': 'undefined-normal', 'debug': [from,to]})
endfu

fu! s:identify_visual() abort
  let [from, to] = b:__states[-2:-1]

  if from.line == to.line
    " stay on the same line

    if from.size > to.size
      " lines count reduced (removal or paste)
      let line1 = to.selection1[0]
      let line2 = to.selection2[0]  + from.size - (to.size )

      if abs(line1 - line2) == abs(from.size - to.size)
        " delete or oneline pasting

        if to.selection2[1] == to.selection1[1]
          " the selection has collapsed (deletion was from the first column)
          " TODO unit test
          let col2 = 1
        elseif to.selection2[1] > to.selection1[1]
          let col2 = to.selection2[1] - to.selection1[1] + 1
        else
          let col2 = to.selection2[1] + 1
        endif

        return s:emit({
              \ 'id':    'v-delete-up',
              \ 'line1': line1,
              \ 'line2': line2,
              \ 'col1':  to.selection1[1],
              \ 'col2':  col2
              \ })
      else
        return s:emit({
              \ 'id':    'v-paste-back-size-changing',
              \ 'line1': line1,
              \ 'col1':  to.selection1[1],
              \ 'line2': line2,
              \ 'col2':  s:unknown
              \ })
      endif

    elseif from.size == to.size && to.selection2[0] == from.line
      " if no changes  and on the same line with selection, then it's inline change

      let col1 = to.selection1[1]
      let col2 =  to.selection2[1]
      return s:emit({
            \ 'id':    'v-inline',
            \ 'line1': from.line,
            \ 'line2': from.line,
            \ 'col1':  col1,
            \ 'col2':  col2,
            \ })
    else
      " PASTE??
      let col1 = from.col
      " let last_l = to.selection2[0]  + from.size - (to.size )
      if  to.selection2[1] > to.selection1[1]
        " backward
        let col2 = to.selection2[1] - to.selection1[1] + 1
      else
        let col2 = to.selection2[1] + 1
      endif

      return s:emit({
            \ 'id':    'v-paste-up',
            \ 'line1': to.selection1[0],
            \ 'line2': to.selection2[0],
            \ 'col1':  to.col,
            \ 'col2':  s:unknown,
            \ })
    endif

  elseif from.line > to.line
    " cursor returned back after cancelling the selection
    " removal or pasting

    if from.size == to.size
      " ONLY a paste
      let first = min([from.line, to.line])
      let last  = max([from.line, to.line])

      if from.line == from.size && to.size != 1
        " if ... && not deleting all lines
        let first += 1
      endif

      if  to.selection2[1] > to.selection1[1]
        let col2 = to.selection2[1] - to.selection1[1] + 1
      else
        let col2 = to.selection2[1] + 1
      endif

      return s:emit({
            \ 'id':    'v-paste-forward',
            \ 'line1': to.selection1[0],
            \ 'col1':  to.selection1[1],
            \ 'line2': to.selection2[0],
            \ 'col2':  from.col,
            \ })
    elseif to.size == to.line
      " START AT THE LAST LINE:

      return s:emit({
            \ 'id':    'v-delete-up',
            \ 'line1': to.selection1[0],
            \ 'col1':  to.selection1[1],
            \ 'line2': from.line,
            \ 'col2':  from.col
            \ })
    else

      let line1 = to.selection1[0]
      let line2 = from.line

      if abs(line1 - line2) == abs(from.size - to.size)
        " delete or oneline pasting
        return s:emit({
              \ 'id':    'v-delete-down',
              \ 'line1': line1,
              \ 'col1':  to.selection1[1],
              \ 'line2': line2,
              \ 'col2':  from.col
              \ })
      else
        return s:emit({
              \ 'id':    'v-paste-forward-size-changing',
              \ 'line1': to.selection1[0],
              \ 'col1':  to.selection1[1],
              \ 'line2': from.line,
              \ 'col2':  from.col
              \ })
      endif
    endif
  endif

  return s:emit({'id': 'undefined-visual-block', 'debug': [from, to]})
endfu

fu! s:identify_insert() abort
  let [from, to] = b:__states[-2:-1]
  " TODO handle cj operator (at the moments it's recognized as i-inline-delete2)

  if from.line == to.line
    let [len1, len2] = [strchars(from.current_line), strchars(to.current_line)]
    if from.size == to.size
      " NO LINES REMOVED:

      if len1 > len2
        " TODO handle
        " - (&virtualedit == 'onemore' ? 1 : 0)

        let col1 = min([from.col, to.col])
        let col2 = max([from.col, to.col])
        let col2 = max([col1, col2 - 1]) " TODO

        return s:emit({
              \ 'id': 'i-inline-delete1',
              \ 'line1':         from.line,
              \ 'line2':         from.line,
              \ 'col1':          col1,
              \ 'col2':          col2,
              \ 'original_text': from.current_line,
              \ })
      elseif len1 < len2
        return s:emit({
              \ 'id':    'i-inline-add',
              \ 'line1': from.line,
              \ 'line2': from.line,
              \ 'col1':  min([from.col, to.col]),
              \ 'col2':  max([from.col, to.col]) - 1,
              \ })
      else " len1 == len2
        " ???????? TODO replace mode?
        return s:emit({
              \ 'id': 'i-inline-delete2',
              \ 'line1':         from.line,
              \ 'line2':         from.line,
              \ 'col1':          min([from.col, to.col]),
              \ 'col2':          max([from.col, to.col]) - 1,
              \ 'original_text': from.current_line,
              \ })
      endif
    elseif from.size > to.size
      return s:emit({
            \ 'id': 'i-delete-newline-right',
            \ 'line1': from.line,
            \ 'line2': from.line,
            \ 'col1':  from.col,
            \ 'col2':  from.col })
    else
      return s:emit({'id': 'i-undefined1', 'debug': [from, to]})
    endif
  elseif from.line > to.line
    " Line deleting key is pressed (BS, <C-w> or other) at column 1, line is merged with previous

    return s:emit({
          \ 'id': 'i-delete-newline',
          \ 'line1': to.line,
          \ 'line2': from.line,
          \ 'col1':  to.col,
          \ 'col2':  from.col })
  else " from.line < to.line
    return s:emit({
          \ 'id':    'i-add-newline',
          \ 'line1': from.line,
          \ 'line2': to.line,
          \ 'col1':  from.col,
          \ 'col2':  to.col,
          \ })
  endif

  return s:emit({'id': 'i-undefined', 'debug': [from, to]})
endfu

fu! s:identify_normal_inline(from,to) abort
  let [from,to] = [a:from, a:to]
  let [len1, len2] = [strchars(from.current_line), strchars(to.current_line)]

  if len1 > len2
    " DELETED CHARS:

    if len2 == 0
      " THE LINES IS CLEARED:
      " TODO handle autoindent
      return s:emit({
            \ 'id': 'n-inline2',
            \ 'line1': from.line,
            \ 'line2': from.line,
            \ 'col1':  1,
            \ 'col2':  len1,
            \ })
    elseif from.col > to.col
      " CUSROR PUSHED LEFT:
      "   - delete to the end
      "   - motion to the left

      if to.col == len2 + (&virtualedit ==# 'onemore' ? 1 : 0)
        let col1 = to.col + (&virtualedit ==# 'onemore' ? 0 : 1)
        let col2 = len1
        return s:emit({
              \ 'id': 'n-inline3',
              \ 'line1': from.line,
              \ 'line2': from.line,
              \ 'col1':  col1,
              \ 'col2':  col2,
              \ })
      else
        " CURSOR MOVED LEFT:
        "   - motion left
        "   - text object
        let col1 = to.col
        let col2 = col1 + len1 - len2 - 1
        return s:emit({
              \ 'id': 'n-inline4',
              \ 'line1': from.line,
              \ 'line2': from.line,
              \ 'col1':  col1,
              \ 'col2':  col2,
              \ })
      endif
    elseif from.col == to.col
      let col1 = from.col
      let col2 = col1 + len1 - len2 - 1
      return s:emit({
            \ 'id': 'n-inline6',
            \ 'line1': from.line,
            \ 'line2': from.line,
            \ 'col1':  col1,
            \ 'col2':  col2,
            \ })
    else

      let col1 = from.col
      let col2 = col1 + len1 - len2 - 1
      return s:emit({
            \ 'id': 'n-inline5',
            \ 'line1': from.line,
            \ 'line2': from.line,
            \ 'col1':  col1,
            \ 'col2':  col2,
            \ })
    endif
  elseif len1 == len2
    return s:emit({
          \ 'id': 'n-inline-replace',
          \ 'line1': from.line,
          \ 'line2': to.line,
          \ 'col1':  from.col,
          \ 'col2':  to.col,
          \ })
  else " len1 < len2
    return s:emit({
          \ 'id': 'n-inline-paste',
          \ 'line1': from.line,
          \ 'line2': to.line,
          \ 'col1':  from.col,
          \ 'col2':  to.col,
          \ })
  endif
endfu

fu! s:last_col(from, to, line2) abort
  try
    silent noau undo

    let end_line = getline(a:line2)
    if s:String.ends_with(end_line, a:to.current_line[a:from.col :])
      let tail_size = strchars(a:to.current_line[a:from.col :])
      return strchars(end_line[: strchars(end_line) - tail_size - 1 ])
    else
      throw 'cannot find the last column'
    endif


  finally
    exe 'silent noau undo '.a:to.changenr
  endtry
endfu

fu! s:is_joining(from, to, line1, line2) abort
  try
    silent noau undo

    let start = 0
    let lines = getline(a:line1, a:line2)
    for text in lines
      if empty(text)
        continue
      endif

      let text_without_leading_whitespaces = substitute(text, '^\s\+', ' ', '')
      let index = stridx(a:to.current_line, text_without_leading_whitespaces, start)
      if index == -1
        return 0
      endif

      let start = index + strchars(text_without_leading_whitespaces) - 1
    endfor
  finally
    exe 'silent noau undo '.a:to.changenr
  endtry

  return 1
endfu

if g:esearch#env isnot 0
  fu! s:debug_observer(event) abort
    PP a:event
  endfu

  command! -nargs=* ST call s:debug_states(<f-args>)
  command! -nargs=* CT call s:debug_changes(<f-args>)
  command! S  echo "\n".join(b:__states,  "\n")
  command! C  echo "\n".join(b:__changes, "\n")
  command! U  call esearch#changes#unlisten_for_current_buffer()
  command! SetupChanges  call esearch#changes#listen_for_current_buffer()
        \ | call esearch#changes#add_observer(function('s:debug_observer'))


  fu! s:debug_changes(...) abort
    let n = get(a:000, 1, 8)
    let tail = copy(b:__changes[max([ - n, - len(b:__changes)  ]) :-1])
    PP tail
  endfu

  fu! s:debug_states(...) abort
    let n = get(a:000, 1, 8)
    let tail = copy(b:__states[max([ - n, - len(b:__states)  ]) :-1])
    let tail = map(tail, '{ "pos": [v:val.line, v:val.col], "id": v:val.id, "changenr": v:val.changenr,'
          \ .'"mode": v:val.mode,'
          \ . '"selections": v:val.selection1 + v:val.selection2}')

    PP tail
  endfu
endif
