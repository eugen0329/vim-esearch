let s:Vital   = vital#esearch#new()
let s:String  = s:Vital.import('Data.String')
let s:unknown = -1
let s:null = 0

" NOTES:
"   - v:operator ==# 'J' is working only for visual mode. In normal it's not set

fu! esearch#changes#listen_for_current_buffer(...) abort
  let b:__states = []
  if g:esearch#env isnot# 0
    let b:__events = []
  endif
  let b:__incrementable_state_id = 0
  let b:__observer = function('<SID>noop')
  let b:__locked = 0
  let b:__pending_change_event = 0
  let b:__pending_o_event = 0
  let b:__pending_insert_leave_event = s:null
  " TODO reimplement to work using :au User 
  let b:__multicursor = 0

  if a:0 > 0
    let b:__undotree = a:1
  else
    let b:__undotree = esearch#undotree#new({})
  endif
  call setline(1, getline(1)) " initialize undo

  call s:record_state_change('n')
  call s:record_state_change('n')

  augroup ESearchChanges
    au! * <buffer>
    au InsertEnter                           <buffer> call s:record_insert_enter('i')
    au CursorMoved                           <buffer> call s:record_state_change('n')
    au CursorMovedI                          <buffer> call s:record_state_change('i')
    au TextChanged,TextChangedI,TextChangedP <buffer> call s:identify_text_change(v:event)

    au InsertLeave <buffer> call timer_start(0, function('s:handle_insert_leave'))

    " TODO reimplement to work using :au User 
    au User MultipleCursorsPre let b:__multicursor = 1
    au User MultipleCursorsPost let b:__multicursor = 0
  augroup END
endfu

fu! s:handle_insert_leave(timer) abort
  if b:__pending_insert_leave_event isnot# s:null
    call s:emit(b:__pending_insert_leave_event)
    let b:__pending_insert_leave_event = s:null
  endif
endfu

fu! s:record_insert_enter(mode) abort
  if b:__locked
    return
  endif

  let payload =  s:payload()
  if a:mode ==# 'i'
    let payload.mode = a:mode
    let payload.enter = 1
  endif

  let from = b:__states[-1]

  if a:mode ==# 'i' && from.mode !=# 'i'
        \ && from.changedtick != b:changedtick
        \ && v:operator ==# 'c'
    let b:__pending_change_event = 1
  elseif a:mode ==# 'i' && from.mode !=# 'i'
        \ && from.changedtick != b:changedtick
        \ && from.size == line('$') - 1
    let b:__pending_o_event = 1
  elseif a:mode ==# 'i' && from.mode ==# "\<C-v>"
          \ && from.changedtick == b:changedtick
    let selection1 = getpos("'<")[1:2]
    let selection2 = getpos("'>")[1:2]
    let b:__pending_insert_leave_event = {
          \ 'id': 'insert-leave-blockwise-visual',
          \ 'line1': selection1[0],
          \ 'col1':  selection1[1],
          \ 'line2': selection2[0],
          \ 'col2':  selection2[1],
          \ 'begin_line': line('.'),
          \ 'begin_col': col('.'),
          \ }
  else
    call add(b:__states, payload)
  endif

  if len(b:__states) > 5000
    let b:__states = b:__states[-100:]
  endif
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
  call remove(b:__states, -1)
  return b:__states[-1].changenr
endfu

fu! esearch#changes#lock() abort
  let b:__locked = 1
endfu
fu! esearch#changes#unlock() abort
  let b:__locked = 0
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
        \ 'cmdhistnr':    histnr(':'),
        \ 'changedtick':  b:changedtick,
        \ }
endfu

fu! s:record_state_change(mode) abort
  if b:__locked
    return
  endif

  let payload =  s:payload()
  if a:mode ==# 'i'
    let payload.mode = a:mode
  endif

  call add(b:__states, payload)
  if len(b:__states) > 5000
    let b:__states = b:__states[-100:]
  endif
endfu

fu! s:identify_text_change(event) abort
  if b:__locked
    return
  endif

  let [from, to] = b:__states[-2:-1]

  if mode() !=# to.mode || to.line != line('.') || to.col != col('.')
    " Missed event
    call s:record_state_change('n')
  endif

  let undotree = undotree()
  if undotree.seq_last > undotree.seq_cur
    " Last undo block number is lower the current - 100% undo
    call s:identify_undo_traversal()
    return
  elseif to.mode !=# 'i'
        \  && has_key(b:__undotree.nodes, changenr())
        \  && from.changedtick != to.changedtick
        \  && !b:__multicursor

    if from.changenr < to.changenr
      " Redo or a third party plugin trick with locking undo
      call s:identify_undo_traversal()
      return
    else
      " noop, undo was reverted (EasyMotion, Overcommandline etc. do this)
      return
    endif
  elseif b:__pending_o_event
    let b:__pending_o_event = 0
    call s:insert_enter_with_o()
  elseif from.cmdhistnr !=# to.cmdhistnr
    call s:identify_cmdline()
  elseif from.mode ==# 'i'
    call s:identify_insert()
  elseif from.mode ==# 'V' || to.mode ==# 'V'
    call s:identify_visual_line()
  elseif from.mode ==# "\<C-v>" || to.mode ==# "\<C-v>"
    call s:identify_visual_block()
  elseif from.mode ==# 'v'
    call s:identify_visual()
  elseif from.mode ==# 'n'
    call s:identify_normal()
  else
    call s:emit({'id': 'undefined-mode', 'mode': [from.mode, to.mode]})
  endif
endfu

fu! s:identify_visual_block() abort
  let [from, to] = b:__states[-2:-1]

  let [col1, col2] = sort([to.selection1[1], to.selection2[1]], 'n')
  let line1 = to.selection1[0]
  let line2 = to.selection2[0]

  if v:operator ==# 'J' && s:is_joining(from, to, line1, line2)
    return s:emit({
          \ 'id':    'blockwise-v-join',
          \ 'line1':    line1,
          \ 'line2':    line2,
          \ })
  else
    let b:__pending_insert_leave_event = {
          \ 'id': 'insert-leave-blockwise-visual',
          \ 'line1': line1,
          \ 'line2': line2,
          \ 'col1':  col1,
          \ 'col2':  col2,
          \ 'begin_line': line('.'),
          \ 'begin_col': col('.'),
          \ }

    return s:emit({
          \ 'id': 'blockwise-visual',
          \ 'line1': line1,
          \ 'line2': line2,
          \ 'col1':  col1,
          \ 'col2':  col2,
          \ })
  endif
endfu

fu! s:insert_enter_with_o() abort
  let [from, to] = b:__states[-2:-1]

  if from.line > to.line
    let b:__pending_insert_leave_event = {
          \ 'id': 'insert-leave-o',
          \ 'line1': to.line,
          \ 'line2': to.line - (v:count1 - 1),
          \ }
  else
    let b:__pending_insert_leave_event = {
          \ 'id': 'insert-leave-o',
          \ 'line1': to.line,
          \ 'line2': to.line + (v:count1 - 1),
          \ }
  endif

  return s:emit({
        \ 'id': 'insert-enter-o',
        \ 'line1': to.line,
        \ 'line2': to.line,
        \ })
endfu

fu! s:identify_cmdline() abort
  let [from, to] = b:__states[-2:-1]
  let line1 = line("'[")

  let ds = from.size - to.size

  if from.size > to.size
    return s:emit({
          \ 'id':            'cmdline1',
          \ 'cmdline':       histget(':', -1),
          \ 'line1':         line1,
          \ 'line2':         line1  + to.size - from.size,
          \ 'original_size': from.size,
          \ 'changenr1':     from.changenr,
          \ 'changenr2':     to.changenr,
          \ })
  else
    return s:emit({
          \ 'id':     'cmdline2',
          \ 'cmdline': histget(':', -1),
          \ 'line1':   line1,
          \ 'line2':   line("']"),
          \ 'original_size': from.size,
          \ 'changenr1': from.changenr,
          \ 'changenr2': to.changenr,
          \ })
  endif
endfu

fu! esearch#changes#add_observer(funcref) abort
  let b:__observer = a:funcref
endfu

" v:opeartor variable isn't reset until another operator is used, so to reset
" them no-op operator is triggererd with set operatorfunc= | norm! g@
if g:esearch#env is# 0
  " If production - don't store events
  fu! s:emit(event) abort
    let a:event.sid = b:__states[-1].id

    if b:__pending_change_event
      let a:event.is_change = 1
      let b:__pending_change_event = 0
      set operatorfunc=
      norm! g@
    else
      let a:event.is_change = 0
    endif
    call b:__observer(a:event)
  endfu
else
  fu! s:emit(event) abort
    let a:event.sid = b:__states[-1].id

    if b:__pending_change_event
      let a:event.is_change = 1
      let b:__pending_change_event = 0
      set operatorfunc=
      norm! g@
    else
      let a:event.is_change = 0
    endif
    call add(b:__events, a:event)
    call b:__observer(a:event)
  endfu
endif

fu! s:identify_undo_traversal() abort
  let [from, to] = b:__states[-2:-1]
  " TODO implement more sophisticated check for undo kind detecting to take
  " different tree branches into account. If belongs to different branches -
  " it's only undo
  return s:emit({
        \ 'id': 'undo-traversal',
        \ 'changenr': b:__states[-1].changenr,
        \ 'kind': (from.changenr < to.changenr ? 'redo' : 'undo'),
        \ })
endfu

fu! s:identify_visual_line() abort
  let [from, to] = b:__states[-2:-1]

  let kind = (b:__pending_change_event ? 'change' : 'motion')

  if from.line == to.line
    " CURSOR IS ON THE SAME LINE:
    "   - paste  moving up
    "   - paste  replacing a single line
    "   - delete moving up
    let line1 = to.line


    if kind ==# 'change'
      " TODO unit tests
      undo
      let [line1, line2] = [line("'["), line("']")]
      redo
      return s:emit({'id': 'V-line-change-..2', 'line1': line1, 'line2': line2})
    endif


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
        if (empty(to.current_line) && to.size == 1) || s:is_delete_up(from, to, line2)
          return s:emit({
                \ 'id':     'V-line-delete-up1',
                \ 'line1':  line1,
                \ 'line2':  line2,
                \ })
        endif
        let line2 = line1 + from.size - to.size + to.selection2[0] - to.selection1[0]

        if v:operator ==# 'J' && s:is_joining(from, to, line1, line2)
          return s:emit({
                \ 'id':    'V-join3',
                \ 'line1':    line1,
                \ 'line2':    line2,
                \ })
        elseif b:__pending_change_event
          return s:emit({
                \ 'id':    'V-line-change1',
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
        if v:operator ==# 'J' && s:is_joining(from, to, line1, line2)
          return s:emit({
                \ 'id':    'V-join4',
                \ 'line1':    line1,
                \ 'line2':    line2,
                \ })
        elseif b:__pending_change_event
          return s:emit({
                \ 'id':    'V-line-change2',
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
              \ 'id':    'V-line-paste-up1',
              \ 'line1': from.line,
              \ 'line2': s:unknown,
              \ })
      else
        return s:emit({
              \ 'id':    'V-line-paste-up2',
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

      if v:operator ==# 'J' && s:is_joining(from, to, line1, line2)
        return s:emit({
              \ 'id':    'V-join1',
              \ 'line1': line1,
              \ 'line2': line2,
              \ })
      else

        if kind ==# 'change'
          " TODO unit tests
          undo
          let [line1, line2] = [line("'["), line("']")]
          redo
          return s:emit({'id': 'V-line-delete1', 'line1': line1, 'line2': line2})
        endif

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

      if v:operator ==# 'J' && s:is_joining(from, to, to.line, from.line)
        return s:emit({
              \ 'id': 'V-join2',
              \ 'line1': to.line,
              \ 'line2': from.line,
              \ })
      elseif b:__pending_change_event
        " TODO unit tests
        return s:emit({
              \ 'id':    'V-line-change3',
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

  let kind = (b:__pending_change_event ? 'change' : 'motion')

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


      if kind ==# 'change'
        " TODO unit tests
        undo
        let [line1, line2] = [line("'["), line("']")]
        redo
      endif


      if s:is_joining(from, to, line1, line2)
        " NOTE when joining empty lines it's equivalent to motion down
        return s:emit({ 'id': 'n-join', 'line1': line1, 'line2': line2})
      elseif from.col == 1 || from.col >= 2 && from.current_line[: from.col - 2 ] == to.current_line[: from.col - 2 ]
        " LINE PREFIXES ARE EQUAL:
        "   - columnwise motion right

        let col2 = s:columnwise_delete_end_column(from, to, line2 + (kind ==# 'change' ? 0 : 1)) - 1

        if from.col == 1 && (col2 < 1)
          return s:emit({
                \ 'id': 'n-' . kind . '-down4',
                \ 'line1': line1,
                \ 'line2': line2,
                \ })

        elseif (&virtualedit ==# 'onemore' && strchars(to.current_line) == to.col - 1)
              \ || (strchars(to.current_line) == to.col && to.col == from.col - 1)
          " IF:
          "   - on the last virtual column
          "   - OR the last column and cursor shifted one column left
          " then the end of deleted region is linewise

          if from.col == 1
            return s:emit({
                  \ 'id': 'n-' . kind . '-down5',
                  \ 'line1': line1,
                  \ 'line2': line2 + (kind ==# 'change' ? 0 : 1),
                  \ })
          else
            return s:emit({
                  \ 'id': 'n-' . kind . '-down-columnwise-right1',
                  \ 'col1':  from.col,
                  \ 'line1': line1,
                  \ 'line2': line2 + (kind ==# 'change' ? 0 : 1),
                  \ })
          endif
        else
          "   - both sides of the region are linewise (clever-f or other motions)
          return s:emit({
                \ 'id': 'n-' . kind . '-down-columnwise-right2',
                \ 'col1':  from.col,
                \ 'line1': line1,
                \ 'line2': line2 + (kind ==# 'change' ? 0 : 1),
                \ 'col2': col2,
                \ })
        endif
      else
        return s:emit({ 'id': 'n-' . kind . '-down2', 'line1': line1, 'line2': line2})
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

    if kind ==# 'change'
      undo
      let [line1, line2] = [line("'["), line("']")]
      redo

      if to.size == from.size && to.changenr != from.changenr
        " TODO acceptance test
        return s:emit({
              \ 'id': 'n-inline-repeat-gn-up',
              \ 'line1': line1,
              \ 'line2': line2,
              \ 'col1':  col('.'),
              \ 'col2':  to.col + 1,
              \ })
      else
        " TODO unit tests
        return s:emit({'id': 'n-change-up3', 'line1': line1, 'line2': line2})
      endif
    endif

    " LINES DIRTY CHECK
    if to.current_line == from.next_line
      let line1 = min([from.line, to.line])
      let line2  = max([from.line, to.line])

      if from.line == from.size && to.size != 1
        let line1 += 1
      endif

      return s:emit({'id': 'n-' . kind . '-up1', 'line1': line1, 'line2': line2})
    elseif to.size == to.line
      " START AT THE LAST LINE:


      if from.current_line[from.col - 1  : ] == to.current_line[to.col - 1 : ]
        " to.col == 1 ||  from.col >= 2 && 
        " POSTFIXES PREFIXES ARE EQUAL:
        return s:emit({
              \ 'id':    'n-' . kind . '-up-columnwise-left2',
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

        return s:emit({'id': 'n-' . kind . '-up2', 'line1': line1, 'line2': from.size})
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
              \ 'id':    'n-' . kind . '-up-columnwise-left1',
              \ 'line1': to.line,
              \ 'line2': from.line,
              \ 'col1':  to.col,
              \ 'col2':  from.col,
              \ 'lastcol': from.lastcol,
              \ })
      elseif from.size == to.size
        " so far only appears while using multicursor
        return s:emit({
              \ 'id': 'n-inline7',
              \ 'line1': to.line,
              \ 'col1': col("'["),
              \ 'col2': col("']"),
              \ })
      else
        let line1 =  to.line
        let line2 =  to.line + from.size - to.size - 1
        return s:emit({
              \ 'id': 'n-' . kind . '-down3',
              \ 'line1': line1,
              \ 'line2': line2
              \ })
      endif
    endif
  else " from.line < to.line
    " CURSOR JUMPS DOWN:

    if to.size == from.size && to.changenr != from.changenr
      " TODO acceptance tests
      let [line1, col1] = getpos("'[")[1:2]
      let [line2, col2] = getpos("']")[1:2]
      return s:emit({
            \ 'id': 'n-inline-repeat-gn-down',
            \ 'line1': line1,
            \ 'line2': line2,
            \ 'col1':  col1,
            \ 'col2':  col2,
            \ })
    elseif to.size == from.size
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

      return s:emit({ 'id': 'n-' . kind . '-up4', 'line1': line1, 'line2': line2})
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


      if v:operator ==# 'J' && s:is_joining(from, to, line1, line2)
        return s:emit({
              \ 'id':    'v-join1',
              \ 'line1': line1,
              \ 'line2': line2,
              \ })
      endif

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

      " let line1 = to.selection1[0]
      " let line2 = from.line
      noau undo
      let [line1, line2] = [line("'["), line("']")]
      noau redo

      if v:operator ==# 'J' && s:is_joining(from, to, line1, line2)
        return s:emit({
              \ 'id':    'v-join2',
              \ 'line1': line1,
              \ 'line2': line2,
              \ })
      endif

      if abs(line1 - line2) == abs(from.size - to.size)
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
              \ 'col2':  max([1, max([from.col, to.col]) - 1]),
              \ })
      else " len1 == len2
        " ???????? TODO replace mode?
        return s:emit({
              \ 'id': 'i-inline-delete2',
              \ 'line1':         from.line,
              \ 'line2':         from.line,
              \ 'col1':          min([from.col, to.col]),
              \ 'col2':  max([1, max([from.col, to.col]) - 1]),
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
      return s:emit({'id': 'i-undefined1'})
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
          \ 'original_text':  from.current_line,
          \ })
  endif

  " return s:emit({'id': 'i-undefined', 'debug': [from, to]})
  return s:emit({'id': 'i-undefined'})
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

fu! s:columnwise_delete_end_column(from, to, line2) abort
  if empty(a:to.current_line)
    " TODO unit tests
    return -1
  endif

  " return col("']")
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

fu! s:is_delete_up(from, to, line2) abort
  " TODO find more graceful way
  try
    silent noau undo
    return getline(a:line2 + 1) == a:to.current_line
  finally
    exe 'silent noau undo '.a:to.changenr
  endtry
endfu

if g:esearch#env isnot 0
  fu! s:debug_observer(event) abort
    PP a:event
  endfu

  command! -nargs=* ST call s:debug_states(<f-args>)
  command! -nargs=* ET call s:debug_changes(<f-args>)
  command! S  echo "\n".join(b:__states,  "\n")
  command! E  echo "\n".join(b:__events, "\n")
  command! U  call esearch#changes#unlisten_for_current_buffer()
  command! SetupChanges  call esearch#changes#listen_for_current_buffer()
        \ | call esearch#changes#add_observer(function('s:debug_observer'))


  fu! s:debug_changes(...) abort
    let n = str2nr(get(a:000, 0, 8))
    let tail = copy(b:__events[max([ - n, - len(b:__events)  ]) :])
    PP tail
  endfu

  fu! s:debug_states(...) abort
    let n = str2nr(get(a:000, 0, 8))
    let tail = copy(b:__states[max([ - n, - len(b:__states)  ]) :])
    let tail = map(tail, '{ "pos": [v:val.line, v:val.col], "id": v:val.id, "changenr": v:val.changenr,'
          \ . '"mode": v:val.mode,'
          \ . '"changedtick": v:val.changedtick,'
          \ . '"selections": v:val.selection1 + v:val.selection2}')

    PP tail
  endfu
endif
