let s:null = 0
let s:sign_id = 1
let s:sign_name = 'ESearchPreviewMatchedLine'
let s:sign_group = 'ESearchPreviewSigns'
let s:events = join([
      \ 'CmdlineEnter',
      \ 'QuitPre',
      \ 'ExitPre',
      \ 'CursorMoved',
      \ 'BufEnter',
      \ 'BufWinEnter',
      \ 'WinLeave',
      \ 'BufWinLeave',
      \ 'BufLeave',
      \ ], ',')
let s:preview_buffers_registry = {}
let s:preview_window = s:null

" TODO testing scenarios (currently blocked by editor version)
"   - file with a name required to be escaped
"   - new buffers bloat
"   - bouncing
"   - buffers with existing swaps
fu! esearch#preview#start() abort
  let filename = esearch#out#win#filename()

  if getfsize(filename) > 50 * 1024
    return s:using_readlines_strategy(filename)
  else
    return s:using_edit_strategy(filename)
  endif
endfu

fu! esearch#preview#is_available() abort
  return has('nvim') && exists('*nvim_open_win')
endfu

fu! s:using_readlines_strategy(filename) abort
  let filename = a:filename
  let [width, height] = [120, 11]

  let lines = readfile(filename)
  let preview_buffer = s:create_buffer(filename, 1)

  try
    call s:set_context_lines(preview_buffer, lines, height)
    call s:close_preview_window()
    let s:preview_window = s:open_preview_window(preview_buffer.id, width, height)
    call s:setup_pseudo_file_appearance(filename, preview_buffer, s:preview_window)
    call s:jump_to_window(s:preview_window.number)
    call s:setup_autoclose_events()
  catch
    call s:close_preview_window()
    echoerr v:exception
  finally
    let preview_buffer.newly_created = 0
  endtry
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

fu! s:set_context_lines(preview_buffer, lines, height) abort
  let lines = a:lines
  let line_in_file = esearch#out#win#line_in_file()
  let column_in_file = esearch#out#win#column_in_file()

  let lines_size = len(lines)

  " TODO reafactor when automation is ready (pending on the editor update)
  if lines_size < a:height
    " File smallar then a:height
    let from = 0
    let to = lines_size
    let line_with_match = line_in_file - 1
  elseif lines_size - line_in_file < a:height / 2
    " closer to the end then half of the height
    let from = lines_size - a:height
    let to = lines_size
    let line_with_match = line_in_file - from - 1
  elseif line_in_file  < a:height / 2
    " closer to the beginning then half of the height
    let from =  0
    let to = a:height
    let line_with_match = line_in_file-1
  else
    " Enough of room up and down
    let from =  line_in_file - a:height / 2 - 1
    let to = line_in_file + a:height / 2
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

fu! s:using_edit_strategy(filename) abort
  let filename = a:filename
  let line_in_file = esearch#out#win#line_in_file()
  let column_in_file = esearch#out#win#column_in_file()

  let search_window = bufwinnr(bufnr('%'))
  let preview_buffer = s:create_buffer(filename, 0)

  let [width, height] = [120, 11]

  try
    call s:close_preview_window()
    let s:preview_window = s:open_preview_window(preview_buffer.id, width, height)
    if preview_buffer.newly_created
      call s:save_options(preview_buffer)
    endif

    call s:jump_to_window(s:preview_window.number)
    call s:edit_file(filename, preview_buffer)
    call s:setup_edited_file_highlight()
    call s:setup_matching_line_sign(line_in_file)
    call s:reshape_preview_window(line_in_file, column_in_file, height)
    call s:setup_on_user_opens_buffer_events()
    call s:setup_autoclose_events()
  catch
    call s:close_preview_window()
    echoerr v:exception
  finally
    let preview_buffer.newly_created = 0
    call s:jump_to_window(search_window)
  endtry
endfu

fu! s:save_options(preview_buffer) abort
  " let a:preview_buffer.guard.winhighlight = nvim_win_get_option(s:preview_window.id, 'winhighlight')
  let a:preview_buffer.guard.swapfile = !!nvim_buf_get_option(a:preview_buffer.id, 'swapfile')
  " let a:preview_buffer.guard.signcolumn = nvim_win_get_option(s:preview_window.id, 'signcolumn')
endfu

fu! s:setup_on_user_opens_buffer_events() abort
  augroup ESearchPreview
    au! BufWinEnter,BufEnter <buffer>
    noautocmd au BufWinEnter,BufEnter <buffer> ++once call s:make_preview_buffer_regular()
  augroup END
endfu

fu! s:setup_autoclose_events() abort
  exe 'au ' . s:events . ' * ++once call s:close_preview_window()'
endfu

fu! s:setup_matching_line_sign(line_in_file) abort
  if empty(sign_getdefined(s:sign_name))
    call sign_define(s:sign_name, {'text': '->'})
  endif

  noautocmd setlocal signcolumn=auto
  noautocmd call sign_place(s:sign_id,
        \ s:sign_group,
        \ s:sign_name,
        \ bufnr('%'),
        \ {'lnum': a:line_in_file})
endfu

" Internal winrestview() has a lot of side effects so s:reshape_preview_window
" should be invoken as later as possible
fu! s:reshape_preview_window(line_in_file, column_in_file, height) abort
  let lines_size = line('$')
  exe 'noautocmd keepjumps resize '. a:height

  if lines_size < a:height
    return cursor(a:line_in_file, a:column_in_file)
  endif

  " literally what :help scrolloff does, but without dealing with options
  if lines_size - a:line_in_file < a:height
    let topline = lines_size - a:height
  else
    let topline = a:line_in_file - (a:height / 2)
  endif
  noautocmd keepjumps call winrestview({
        \ 'lnum': a:line_in_file,
        \ 'col': a:column_in_file,
        \ 'topline': topline,
        \ })
endfu

fu! s:setup_edited_file_highlight() abort
  noautocmd keepjumps setlocal winhighlight=Normal:NormalFloat
  keepjumps doau BufReadPre
  keepjumps doau BufRead
endfu

fu! s:open_preview_window(preview_buffer, width, height) abort
  let p = getpos('.')[1]
  if line('w$') - p < a:height
    let row = (getpos('.')[1] - line('w0')) - a:height
  else
    let row = (getpos('.')[1] - line('w0') + 1)
  endif
  let id = nvim_open_win(a:preview_buffer, 0, {
        \ 'width':     a:width,
        \ 'height':    a:height,
        \ 'focusable': v:false,
        \ 'row':       row,
        \ 'col':       max([5, wincol() - 1]),
        \'relative':   'win',
        \})
  let data = {'id': id, 'number': win_id2win(id), 'guard': {}}
  let data.guard.winhighlight = nvim_win_get_option(id, 'winhighlight')
  let data.guard.signcolumn = nvim_win_get_option(id, 'signcolumn')
  return data
endfu

fu! s:edit_file(filename, preview_buffer) abort
  if expand('%:p') !=# a:filename
    exe 'keepjumps noautocmd noswapfile edit! ' . fnameescape(a:filename)

    " if buffer is already created, vim switches to it leaving empty buffer we
    " have to cleanup
    let current_buffer_id = bufnr('%')
    if current_buffer_id != a:preview_buffer.id
      exe a:preview_buffer.id . 'bwipeout'
      let a:preview_buffer.id = current_buffer_id
    endif

    return 1
  endif

  return 0
endfu

fu! s:jump_to_window(window) abort
  noautocmd keepjumps exe a:window . 'wincmd w'
endfu

fu! s:make_preview_buffer_regular() abort
  let current_filename = expand('%:p')

  if !has_key(s:preview_buffers_registry, current_filename)
    " execute once guard
    return
  endif

  let preview_buffer = s:preview_buffers_registry[current_filename]
  " let &l:winhighlight = preview_buffer.guard.winhighlight
  " let &l:signcolumn = preview_buffer.guard.signcolumn
  try
    let &l:swapfile = preview_buffer.guard.swapfile
  catch /:E325:/
    " User is already prompted about existing swap at the moment. Suppress.
    " Occurs when preview is opened and :new command is executed
  finally
    call remove(s:preview_buffers_registry, current_filename)
  endtry

  " prevent other events to handle the buffer again
  au! ESearchPreview BufWinEnter,BufEnter <buffer>
endfu

fu! s:create_buffer(filename, disposable) abort
  " if has_key(s:preview_buffers_registry, a:filename)
  if bufexists(a:filename)
    let s:preview_buffers_registry[a:filename] = {
          \ 'id': bufnr('^' . a:filename . '$'),
          \ 'filename': a:filename,
          \ 'newly_created': 0,
          \ 'is_opened': 0,
          \ 'guard': {},
          \ }
    return s:preview_buffers_registry[a:filename]
  endif

  if a:disposable
    let id = nvim_create_buf(0, 1)
  else
    let id = nvim_create_buf(1, 0)
  endif

  let s:preview_buffers_registry[a:filename] = {
        \ 'id': id,
        \ 'filename': a:filename,
        \ 'newly_created': 1,
        \ 'is_opened': 0,
        \ 'guard': {},
        \ }
  return s:preview_buffers_registry[a:filename]
endfu

fu! s:close_preview_window() abort
  if s:preview_window isnot# s:null
    call nvim_win_set_option(s:preview_window.id, 'winhighlight', s:preview_window.guard.winhighlight)
    call nvim_win_set_option(s:preview_window.id, 'signcolumn', s:preview_window.guard.signcolumn)
    exe s:preview_window.number . 'close'
    let s:preview_window = s:null
  endif

  call sign_unplace(s:sign_group, {'id': s:sign_id})
endfu
