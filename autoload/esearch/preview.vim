let s:Guard   = vital#esearch#import('Vim.Guard')
let s:Message = vital#esearch#import('Vim.Message')
let s:null = 0
let s:sign_id = 1
let s:sign_name = 'ESearchPreviewMatchedLine'
let s:sign_group = 'ESearchPreviewSigns'
let s:autoclose_events = join([
      \ 'CursorMoved',
      \ 'CursorMovedI',
      \ 'InsertEnter',
      \ 'QuitPre',
      \ 'ExitPre',
      \ 'BufEnter',
      \ 'BufWinEnter',
      \ 'WinLeave',
      \ ], ',')

let g:esearch#preview#buffers = {}
let g:esearch#preview#win = s:null
let g:esearch#preview#cache = esearch#cache#lru#new(20)
let g:esearch#preview#scratches = esearch#cache#lru#new(5)
" TODO
" - separate strategies when it's clear how how vim's floats are implemented
" - Extract signs placing code
" - Set local options using a context manager

fu! esearch#preview#start(filename, line, ...) abort
  if !filereadable(a:filename)
    return 0
  endif

  let opts = get(a:000, 0, {})
  let max_edit_size = get(opts, 'max_edit_size', 100 * 1024) " size in bytes
  let geometry = {
        \ 'winline': winline(),
        \ 'wincol':  wincol(),
        \ 'width':   get(opts, 'width', 120),
        \ 'height':  get(opts, 'height', 11),
        \ }

  if getfsize(a:filename) > max_edit_size
    return s:preview_in_scratch(a:filename, a:line, geometry)
  else
    return s:preview_in_regular_buffer(a:filename, a:line, geometry)
  endif
endfu

fu! esearch#preview#is_open() abort
  " window id becomes invalid on bwipeout
  return g:esearch#preview#win isnot# s:null
        \ && nvim_win_is_valid(g:esearch#preview#win.id)
endfu

fu! esearch#preview#reset() abort
  " If #close() is used on every liste event, it can cause a bug where previewed
  " buffer loose it's content on open, so this method is defined to 
  if esearch#preview#is_open()
    let id = g:esearch#preview#win.id
    let guard = g:esearch#preview#win.guard
    call nvim_win_set_option(id, 'winhighlight', guard.winhighlight)
    call nvim_win_set_option(id, 'signcolumn',   guard.signcolumn)
    call nvim_win_set_option(id, 'foldenable',   guard.foldenable)
  endif
endfu

fu! esearch#preview#close() abort
  if esearch#preview#is_open()
    call esearch#preview#reset()
    call nvim_win_close(g:esearch#preview#win.id, 1)
    let g:esearch#preview#win = s:null
  endif

  call sign_unplace(s:sign_group, {'id': s:sign_id})
endfu

fu! s:preview_in_scratch(filename, line, geometry) abort
  let filename = a:filename
  let line = a:line

  let lines_text = esearch#util#readfile(filename, g:esearch#preview#cache)
  let search_window = bufwinid('%')
  let preview_buffer = s:create_scratch_buffer(filename)

  try
    call esearch#preview#close()
    let g:esearch#preview#win = s:open_preview_window(preview_buffer, a:geometry)
    call s:setup_pseudo_file_appearance(filename, preview_buffer, g:esearch#preview#win)
    call s:jump_to_window(g:esearch#preview#win.id)
    call s:set_context_lines(preview_buffer, lines_text, a:geometry, a:line)
    call s:setup_matching_line_sign(line)
    call s:reshape_preview_window(preview_buffer, line, a:geometry)
    call s:setup_autoclose_events()
  catch
    call esearch#preview#close()
    echoerr v:exception
    return 0
  finally
    let preview_buffer.newly_created = 0
    call s:jump_to_window(search_window)
  endtry

  return 1
endfu

fu! s:setup_pseudo_file_appearance(filename, preview_buffer, preview_window) abort
  let filetype = esearch#ftdetect#complete(a:filename)
  if filetype isnot# s:null
    call nvim_buf_set_option(a:preview_buffer.id, 'filetype', filetype)
  endif
endfu

" Setup context lines prepended by blank lines outside the viewport. syntax_sync_lines offset is added to make syntaxes highlight correct
fu! s:set_context_lines(preview_buffer, lines_text, geometry, line) abort
  let syntax_sync_lines = 100
  let begin = max([a:line - a:geometry.height - syntax_sync_lines, 0])
  let end = min([a:line + a:geometry.height + syntax_sync_lines, len(a:lines_text)])

  let blank_lines = repeat([''], begin)
  let context_lines = a:lines_text[ begin : end]
  call nvim_buf_set_lines(a:preview_buffer.id, 0, -1, 0,
        \ blank_lines + context_lines)

  " Prevent slowdowns on big syntax syncing ranges (according to the doc,
  " 'fromstart' option is equivalent to 'syncing starts ...', but with a large
  " number).
  if match(s:Message.capture('syn sync'), 'syncing starts \d\{3,}') >= 0
    syntax sync clear
    exe printf('syntax sync minlines=%d maxlines=%d',
          \ syntax_sync_lines,
          \ syntax_sync_lines + 1)
  endif
endfu

fu! s:preview_in_regular_buffer(filename, line, geometry) abort
  let filename = a:filename
  let line = a:line

  let search_window = bufwinid('%')
  let preview_buffer = s:create_buffer(filename)

  try
    call esearch#preview#close()
    let g:esearch#preview#win = s:open_preview_window(preview_buffer, a:geometry)
    if preview_buffer.newly_created
      call s:save_options(preview_buffer)
    endif

    call s:jump_to_window(g:esearch#preview#win.id)
    call s:edit_file(filename, preview_buffer)
    call s:configure_edited_preview_buffer()
    call s:setup_matching_line_sign(line)
    call s:reshape_preview_window(preview_buffer, line, a:geometry)
    call s:setup_on_user_opens_buffer_events()
    call s:setup_autoclose_events()
  catch
    call esearch#preview#close()
    echoerr v:exception
    return 0
  finally
    let preview_buffer.newly_created = 0
    call s:jump_to_window(search_window)
  endtry

  return 1
endfu

fu! s:save_options(preview_buffer) abort
  let a:preview_buffer.guard.swapfile = !!nvim_buf_get_option(a:preview_buffer.id, 'swapfile')
endfu

fu! s:setup_on_user_opens_buffer_events() abort
  augroup ESearchPreview
    au!
    au BufWinEnter,BufEnter <buffer> ++once call s:make_preview_buffer_regular()
  augroup END
endfu

fu! s:setup_autoclose_events() abort
  exe 'au ' . s:autoclose_events . ' * ++once call esearch#preview#close()'
  exe 'au ' . s:autoclose_events . ',BufWinLeave,BufLeave * ++once call esearch#preview#reset()'
endfu

fu! s:setup_matching_line_sign(line) abort
  if empty(sign_getdefined(s:sign_name))
    call sign_define(s:sign_name, {'text': '->'})
  endif

  noautocmd setlocal signcolumn=auto
  noautocmd call sign_place(s:sign_id,
        \ s:sign_group,
        \ s:sign_name,
        \ bufnr('%'),
        \ {'lnum': a:line})
endfu

" Builtin winrestview() has a lot of side effects so s:reshape_preview_window
" should be invoken as later as possible
fu! s:reshape_preview_window(preview_buffer, line, geometry) abort
  let a:geometry.height = min([
        \ nvim_buf_line_count(a:preview_buffer.id),
        \ a:geometry.height,
        \ &lines - 1])
  " NOTE that position is calculated twice. First calculation is required for
  " initial positioning, as the window cannot be initialized without row/col.
  " The second calculation is needed to clip the window height to an opened
  " buffer size 
  call s:assign_position(a:geometry)

  let guard = s:Guard.store(['&winminheight'])
  try
    noau set winminheight=1
    call nvim_win_set_config(g:esearch#preview#win.id, {
          \ 'row':       a:geometry.row,
          \ 'col':       a:geometry.col,
          \ 'height':    a:geometry.height,
          \ 'relative': 'win',
          \ })

    " literally what :help 'scrolloff' option does, but without dealing with
    " options
    if line('$') < a:geometry.height
      let topline = 1
    elseif line('$') - a:line < a:geometry.height
      let topline = line('$') - a:geometry.height
    else
      let topline = a:line - (a:geometry.height / 2)
    endif
    noautocmd keepjumps call winrestview({
          \ 'lnum': a:line,
          \ 'col': 1,
          \ 'topline': topline,
          \ })
  finally
    call guard.restore()
  endtry
endfu

fu! s:configure_edited_preview_buffer() abort
  noautocmd keepjumps setlocal winhighlight=Normal:NormalFloat nofoldenable
  keepjumps doau BufReadPre
  keepjumps doau BufRead
endfu

fu! s:assign_position(geometry) abort
  if &lines - a:geometry.height - 1 < a:geometry.winline
    " if there's no room - show above
    let a:geometry.row = a:geometry.winline - a:geometry.height
  else
    let a:geometry.row = a:geometry.winline + 1
  endif
  let a:geometry.col = max([5, a:geometry.wincol - 1])
endfu

fu! s:open_preview_window(preview_buffer, geometry) abort
  call s:assign_position(a:geometry)

  let guard = s:Guard.store(['&shortmess'])
  noau set shortmess+=A
  let id = nvim_open_win(a:preview_buffer.id, 0, {
        \ 'width':     a:geometry.width,
        \ 'height':    a:geometry.height,
        \ 'focusable': v:false,
        \ 'row':       a:geometry.row,
        \ 'col':       a:geometry.col,
        \ 'relative':  'win',
        \})
  call guard.restore()

  let window = {'id': id, 'number': win_id2win(id), 'guard': {}}
  let window.guard.winhighlight = nvim_win_get_option(id, 'winhighlight')
  let window.guard.signcolumn = nvim_win_get_option(id, 'signcolumn')
  let window.guard.foldenable = nvim_win_get_option(id, 'foldenable')
  return window
endfu

fu! s:edit_file(filename, preview_buffer) abort
  if expand('%:p') !=# a:filename

    let guard = s:Guard.store(['&shortmess'])
    noau set shortmess+=A
    exe 'keepjumps noau edit ' . fnameescape(a:filename)
    call guard.restore()

    " if the buffer has already created, vim switches to it leaving an empty
    " buffer we have to cleanup
    let current_buffer_id = bufnr('%')
    if current_buffer_id != a:preview_buffer.id
      if bufexists(a:preview_buffer.id)
        exe a:preview_buffer.id . 'bwipeout'
      endif
      let a:preview_buffer.id = current_buffer_id
    endif

    return 1
  endif

  return 0
endfu

fu! s:jump_to_window(window) abort
  noau keepjumps call nvim_set_current_win(a:window)
endfu

fu! s:make_preview_buffer_regular() abort
  let current_filename = expand('%:p')

  if !has_key(g:esearch#preview#buffers, current_filename)
    " execute once guard
    return
  endif

  let preview_buffer = g:esearch#preview#buffers[current_filename]
  try
    if !empty(preview_buffer.guard)
      let &l:swapfile = preview_buffer.guard.swapfile
    endif
  catch /:E325:/
    " User is already prompted about existing swap at the moment. Suppress.
    " Occurs when preview is opened and :new command is executed
  finally
    call remove(g:esearch#preview#buffers, current_filename)
  endtry
  call esearch#preview#reset()

  " prevent other events to handle the buffer again
  au! ESearchPreview *
endfu

fu! s:create_buffer(filename) abort
  if has_key(g:esearch#preview#buffers, a:filename)
    let buffer = g:esearch#preview#buffers[a:filename]
    if buffer.is_valid()
      return buffer
    endif
    call remove(g:esearch#preview#buffers, a:filename)
  endif

  let buffer = s:Buffer.new(a:filename)
  let g:esearch#preview#buffers[a:filename] = buffer

  return buffer
endfu

fu! s:create_scratch_buffer(filename) abort
  if g:esearch#preview#scratches.has(a:filename)
    let scratch = g:esearch#preview#scratches.get(a:filename)
    if scratch.is_valid()
      return scratch
    endif

    call g:esearch#preview#scratches.remove(a:filename)
  endif

  let scratch = s:ScratchBuffer.new(a:filename)
  call g:esearch#preview#scratches.set(a:filename, scratch)

  return scratch
endfu

fu! s:is_valid_buffer() abort dict
  return nvim_buf_is_valid(self.id)
endfu

let s:Buffer = {
      \ 'guard': {},
      \ 'newly_created': 1,
      \ 'is_valid': function('<SID>is_valid_buffer')}

fu! s:Buffer.new(filename) abort dict
  let instance = copy(self)
  let instance.filename = a:filename

  if bufexists(a:filename)
    let instance.id = bufnr('^'.a:filename.'$')
  else
    let instance.id = nvim_create_buf(1, 0)
  endif

  return instance
endfu

let s:ScratchBuffer = {
      \ 'guard': {},
      \ 'is_valid': function('<SID>is_valid_buffer')}

fu! s:ScratchBuffer.new(filename) abort dict
  let instance = copy(self)
  let instance.filename = a:filename
  let instance.id = nvim_create_buf(0, 1)
  return instance
endfu

fu! s:ScratchBuffer.remove() abort dict
  if !bufexists(self.id) | return | endif
  silent exe self.id 'bwipeout'
endfu
