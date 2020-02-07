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
let g:preview_buffers_registry = {}

let g:debug = []

" TODO testing scenarios
"   - file with a name required to be escaped
"   - new buffers bloat
"   - bouncing
fu! esearch#preview#start() abort
  let filename = esearch#out#win#filename()

  if getfsize(filename) > 50 * 1024
    return s:using_readlines_strategy(filename)
  else
    return s:using_edit_strategy(filename)
  endif
endfu

fu! s:using_readlines_strategy(filename) abort
  let filename = a:filename
  let [width, height] = [120, 11]

  let lines = readfile(filename)
  let preview_buffer = s:create_buffer(filename, 1)

  try
    call s:setlines(preview_buffer, lines, height)
    let g:preview_window = s:open_preview_window(preview_buffer.id, width, height)
    call s:setup_pseudo_file_appearance(filename, preview_buffer, g:preview_window)
    " call s:goto_window(g:preview_window.number)
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

fu! s:setlines(preview_buffer, lines, height) abort
  let lines = a:lines
  let line_in_file = esearch#out#win#line_in_file()
  let column_in_file = esearch#out#win#column_in_file()

  let lines_size = len(lines)
  if lines_size < a:height
    let from = 0
    let to = lines_size
    let at = line_in_file - 1
  elseif lines_size - (line_in_file - 1) < a:height
    let from = lines_size - a:height
    let to = lines_size
    let at = line_in_file - from - 1
  elseif line_in_file - a:height / 2 < 1
    let from =  0
    let to = line_in_file
    let at = line_in_file-1
  else
    " throw 1
    let from =  line_in_file - a:height / 2 - 1
    let to = line_in_file + a:height / 2
    let at = a:height / 2
  endif

  let context = []

  if &numberwidth < len(string(to)) + 2
    let padding = 2+len(string(to))
  else
    let padding = max([&numberwidth, 3+len(string(to))])
  endif


  let lines_format = '%'.padding.'d %s'
  for i in range(from, to-1)
    call add(context, printf(lines_format, i+1, lines[i]))
  endfor

  " TODO handle 'signcolumn'
  let context[at] = substitute(context[at], '^..', '->', '')
  call nvim_buf_set_lines(a:preview_buffer.id, 0, -1, 0, context)
  call assert_equal(len(context),  a:height)
endfu

fu! s:using_edit_strategy(filename) abort
  let filename = a:filename
  let line_in_file = esearch#out#win#line_in_file()
  let column_in_file = esearch#out#win#column_in_file()

  let search_window = bufwinnr(bufnr('%'))
  let preview_buffer = s:create_buffer(filename, 0)

  let [width, height] = [120, 11]

  try
    let g:preview_window = s:open_preview_window(preview_buffer.id, width, height)
    if preview_buffer.newly_created
      call s:save_options(preview_buffer)
    endif

    call s:goto_window(g:preview_window.number)
    call s:edit_file(filename, preview_buffer)
    call s:setup_edited_file_highlight()
    call s:setup_matching_line_sign(line_in_file)
    call s:reshape_preview_window(line_in_file, column_in_file, height)
    call s:setup_on_open_events()
    call s:setup_autoclose_events()
  catch
    call s:close_preview_window()
    echoerr v:exception
  finally
    let preview_buffer.newly_created = 0
    call s:goto_window(search_window)
  endtry
endfu

fu! s:save_options(preview_buffer) abort
  let a:preview_buffer.guard.winhighlight = nvim_win_get_option(g:preview_window.id, 'winhighlight')
  let a:preview_buffer.guard.swapfile = !!nvim_buf_get_option(a:preview_buffer.id, 'swapfile')
  let a:preview_buffer.guard.signcolumn = nvim_win_get_option(g:preview_window.id, 'signcolumn')
endfu

fu! s:setup_on_open_events() abort
  augroup Preview
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

" Internal winrestview has a lot of side effects so s:reshape_preview_window
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
  call add(g:debug, ['reshaping', [topline]])
  noautocmd keepjumps call winrestview({
        \ 'lnum': a:line_in_file,
        \ 'col': a:column_in_file,
        \ 'topline': topline,
        \ })
endfu

fu! s:setup_edited_file_highlight() abort
  " noautocmd keepjumps setlocal winhighlight=Normal:NormalFloat
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
  let number = win_id2win(id)
  return {'id': id, 'number': number}
endfu

fu! s:edit_file(filename, preview_buffer) abort
  if expand('%') !=# a:filename
    noautocmd keepjumps noswapfile exe 'keepjumps noautocmd noswapfile edit! ' . fnameescape(a:filename)

    " if buffer was already created vim switches to it leaving empty buffer we
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

fu! s:goto_window(window) abort
  noautocmd keepjumps exe a:window . 'wincmd w'
endfu

fu! s:make_preview_buffer_regular() abort
  " execute once
  au! Preview BufWinEnter,BufEnter <buffer>

  let current_filename = expand('%')
  call add(g:debug, ['before making regular', current_filename])
  if !has_key(g:preview_buffers_registry, current_filename)
    " another execute once guard
    " shouldn't normally happen because of the command above, but it's
    " acceptable to just suppress.
    return
  endif

  let preview_buffer = g:preview_buffers_registry[current_filename]
  let &l:winhighlight = preview_buffer.guard.winhighlight
  let &l:signcolumn = preview_buffer.guard.signcolumn
  try
    let &l:swapfile = preview_buffer.guard.swapfile
  catch /:E325:/
    " User is already prompted about existing swap at the moment. Suppress.
    " Occurs when preview is opened and :new command is executed
  finally
    call remove(g:preview_buffers_registry, current_filename)
  endtry
  call add(g:debug, ['made regular', preview_buffer])
endfu

fu! s:create_buffer(filename, disposable) abort
  if has_key(g:preview_buffers_registry, a:filename)
    return g:preview_buffers_registry[a:filename]
  endif

  if a:disposable
    let id = nvim_create_buf(0, 1)
  else
    let id = nvim_create_buf(1, 0)
  endif

  let g:preview_buffers_registry[a:filename] = {
        \ 'id': id,
        \ 'filename': a:filename,
        \ 'newly_created': 1,
        \ 'is_opened': 0,
        \ 'guard': {},
        \ }
  return g:preview_buffers_registry[a:filename]
endfu

fu! s:close_preview_window() abort
  call sign_unplace(s:sign_group, {'id': s:sign_id})

  if exists('g:preview_window') && g:preview_window isnot -1
    exe g:preview_window.number . 'close'
    let g:preview_window = -1
  endif
endfu
