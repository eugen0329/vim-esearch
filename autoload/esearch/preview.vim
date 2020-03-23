let s:Guard       = vital#esearch#import('Vim.Guard')

let s:null = 0
let s:sign_id = 1
let s:sign_name = 'ESearchPreviewMatchedLine'
let s:sign_group = 'ESearchPreviewSigns'
let s:autoclose_events = join([
      \ 'CursorMoved',
      \ 'QuitPre',
      \ 'ExitPre',
      \ 'BufEnter',
      \ 'BufWinEnter',
      \ 'WinLeave',
      \ ], ',')

let g:esearch#preview#buffers = {}
let g:esearch#preview#scratches = {}
let g:esearch#preview#window = s:null

fu! esearch#preview#is_open() abort
  " window id becomes invalid on bwipeout
  return g:esearch#preview#window isnot# s:null
        \ && nvim_win_is_valid(g:esearch#preview#window.id)
endfu

fu! esearch#preview#reset() abort
  if esearch#preview#is_open()
    call nvim_win_set_option(g:esearch#preview#window.id, 'winhighlight', g:esearch#preview#window.guard.winhighlight)
    call nvim_win_set_option(g:esearch#preview#window.id, 'signcolumn', g:esearch#preview#window.guard.signcolumn)
    " call nvim_win_set_option(g:esearch#preview#window.id, 'foldlevel', g:esearch#preview#window.guard.foldlevel)
  endif
endfu

fu! esearch#preview#close() abort
  if esearch#preview#is_open()
    call esearch#preview#reset()
    call nvim_win_close(g:esearch#preview#window.id, 1)
    let g:esearch#preview#window = s:null
  endif

  call sign_unplace(s:sign_group, {'id': s:sign_id})
endfu

fu! esearch#preview#start(filename, line, ...) abort
  if !filereadable(a:filename)
    return 0
  endif

  let geometry = {}
  let opts = get(a:000, 0, {})
  let max_edit_size   = get(opts, 'max_edit_size', 50 * 1024) " size in bytes
  " let max_edit_size   = get(opts, 'max_edit_size', 0) " size in bytes
  let geometry.width  = get(opts, 'width', 120)
  let geometry.height = get(opts, 'height', 11)

  if getfsize(a:filename) > max_edit_size
    return s:using_scratch(a:filename, a:line, geometry)
  else
    return s:using_real_buffer(a:filename, a:line, geometry)
  endif
endfu

fu! s:using_scratch(filename, line, geometry) abort
  let filename = a:filename
  let line = a:line
  let [width, height] = [a:geometry.width, a:geometry.height]

  let lines = readfile(filename)
  " let search_window = bufwinnr(bufnr('%'))
  let search_window = bufwinid('%')
  let preview_buffer = s:create_scratch_buffer(filename)

  try
    call s:set_context_lines(preview_buffer, lines, height, a:line)
    call esearch#preview#close()
    let g:esearch#preview#window = s:open_preview_window(preview_buffer, width, height)
    call s:setup_pseudo_file_appearance(filename, preview_buffer, g:esearch#preview#window)
    call s:jump_to_window(g:esearch#preview#window.id)
    call s:reshape_preview_window(line, height)
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
  call nvim_win_set_option(a:preview_window.id, 'number', v:false)
  call nvim_win_set_option(a:preview_window.id, 'list', v:false)  " TODO don't show trailing ws

  let ft = esearch#ftdetect#slow(a:filename)
  if ft isnot 0
    call nvim_buf_set_var(a:preview_buffer.id,    '__esearch_preview_filetype__', ft)
    call nvim_buf_set_option(a:preview_buffer.id, 'filetype', 'esearch_preview')
  endif
endfu

fu! s:set_context_lines(preview_buffer, lines, height, line) abort
  let lines = a:lines
  let line = a:line

  let lines_size = len(lines)

  " TODO reafactor when automation is ready (pending on the editor update)
  if lines_size < a:height
    " File smallar then a:height
    let from = 0
    let to = lines_size
    let line_with_match = line - 1
  elseif lines_size - line < a:height / 2
    " closer to the end then half of the height
    let from = lines_size - a:height
    let to = lines_size
    let line_with_match = line - from - 1
  elseif line  < a:height / 2
    " closer to the beginning then half of the height
    let from =  0
    let to = a:height
    let line_with_match = line-1
  else
    " Enough of room up and down
    let from =  line - a:height / 2 - 1
    let to = line + a:height / 2
    let line_with_match = a:height / 2
  endif

  " TODO take 'signcolumn' value into account
  if &numberwidth < len(string(to)) + 2
    let padding = 2+len(string(to))
  else
    let padding = max([&numberwidth, 3+len(string(to))])
  endif

  let context_lines = []
  let lines_format = '%'.padding.'d %s'
  for i in range(from, to-1)
    call add(context_lines, printf(lines_format, i+1, lines[i]))
  endfor

  let context_lines[line_with_match] = substitute(context_lines[line_with_match], '^..', '->', '')
  call nvim_buf_set_lines(a:preview_buffer.id, 0, -1, 0, context_lines)
  call assert_equal(len(context_lines),  a:height) " TODO remove when tests are ready
endfu

fu! s:using_real_buffer(filename, line, geometry) abort
  let filename = a:filename
  let line = a:line

  " let search_window = bufwinnr(bufnr('%'))
  let search_window = bufwinid('%')
  let preview_buffer = s:create_buffer(filename)

  let [width, height] = [a:geometry.width, a:geometry.height]

  try
    call esearch#preview#close()
    let g:esearch#preview#window = s:open_preview_window(preview_buffer, width, height)
    if preview_buffer.newly_created
      call s:save_options(preview_buffer)
    endif

    call s:jump_to_window(g:esearch#preview#window.id)
    call s:edit_file(filename, preview_buffer)
    call s:setup_edited_file_highlight()
    call s:setup_matching_line_sign(line)
    call s:reshape_preview_window(line, height)
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
fu! s:reshape_preview_window(line, height) abort
  let lines_size = line('$')
  exe 'noautocmd keepjumps resize '. a:height

  if lines_size < a:height
    return cursor(a:line, 0)
  endif

  " literally what :help scrolloff does, but without dealing with options
  if lines_size - a:line < a:height
    let topline = lines_size - a:height
  else
    let topline = a:line - (a:height / 2)
  endif
  noautocmd keepjumps call winrestview({
        \ 'lnum': a:line,
        \ 'col': 1,
        \ 'topline': topline,
        \ })
endfu

fu! s:setup_edited_file_highlight() abort
  noautocmd keepjumps setlocal winhighlight=Normal:NormalFloat
  " noautocmd keepjumps setlocal winhighlight=Normal:NormalFloat foldlevel=1000
  keepjumps doau BufReadPre
  keepjumps doau BufRead
endfu

fu! s:open_preview_window(preview_buffer, width, height) abort
  if  &lines - a:height - 1 < winline()
    let row = winline() - a:height
  else
    let row = winline()
  endif

  let guard = s:Guard.store(['&shortmess'])
  noau set shortmess+=A
  let id = nvim_open_win(a:preview_buffer.id, 0, {
        \ 'width':     a:width,
        \ 'height':    a:height,
        \ 'focusable': v:false,
        \ 'row':       row,
        \ 'col':       max([5, wincol() - 1]),
        \ 'relative':  'win',
        \})
  call guard.restore()

  let data = {'id': id, 'number': win_id2win(id), 'guard': {}}
  let data.guard.winhighlight = nvim_win_get_option(id, 'winhighlight')
  let data.guard.signcolumn = nvim_win_get_option(id, 'signcolumn')
  " let data.guard.foldlevel = nvim_win_get_option(id, 'foldlevel')
  return data
endfu

fu! s:edit_file(filename, preview_buffer) abort
  if expand('%:p') !=# a:filename

    let guard = s:Guard.store(['&shortmess'])
    noau set shortmess+=A
    " if a:preview_buffer.newly_created
      exe 'edit ' . fnameescape(a:filename)
      call nvim_buf_set_name(bufnr(), a:filename)
    " else
    "   exe 'keepjumps noau edit ' . fnameescape(a:filename)
    " endif
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
  " noautocmd keepjumps exe a:window . 'wincmd w'
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

fu! s:create_scratch_buffer(filename) abort
  if has_key(g:esearch#preview#scratches, a:filename) && nvim_buf_is_valid(g:esearch#preview#scratches[a:filename].id)
    return g:esearch#preview#scratches[a:filename]
  endif

  let id = nvim_create_buf(0, 1)

  let g:esearch#preview#scratches[a:filename] = {
        \ 'id':            id,
        \ 'filename':      a:filename,
        \ 'newly_created': 1,
        \ 'is_opened':     0,
        \ 'guard':         {},
        \ }
  return g:esearch#preview#scratches[a:filename]
endfu

fu! s:create_buffer(filename) abort
  if has_key(g:esearch#preview#buffers, a:filename)
    if bufexists(a:filename) && nvim_buf_is_valid(g:esearch#preview#buffers[a:filename].id)
      return g:esearch#preview#buffers[a:filename]
    else
      " buffer is known as a preview, but it was removed using :bwipeout or a
      " similar command
      call remove(g:esearch#preview#buffers, a:filename)
    endif
  endif

  if bufexists(a:filename)
    let id = bufnr('^'.a:filename.'$')
  else
    let id = nvim_create_buf(1, 0)
  endif

  let g:esearch#preview#buffers[a:filename] = {
        \ 'id':            id,
        \ 'filename':      a:filename,
        \ 'newly_created': 1,
        \ 'is_opened':     0,
        \ 'guard':         {},
        \ }
  return g:esearch#preview#buffers[a:filename]
endfu
