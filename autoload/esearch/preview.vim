fu! esearch#preview#start() abort
  let filename = esearch#out#win#filename()
  let line_in_file = esearch#out#win#line_in_file()
  let column_in_file = esearch#out#win#column_in_file()

  let preview_buffer = s:initialize_buffer(filename)
  let search_window = bufwinnr(bufnr('%'))

  try
    let s:preview_window = s:open_preview_window(preview_buffer.id)

    if preview_buffer.is_new
      call s:save_buffer_variables(preview_buffer)
    endif
    call s:goto_window(s:preview_window.number)
    if expand('%') !=# filename
      call s:open_file(filename)
    endif
    call s:reshape_preview_window(line_in_file, column_in_file)
    call s:load_highlight()
    call s:setup_matched_line_sign(line_in_file)
    call s:setup_events()
    exe 'au '.s:events. ' * ++once call s:close_preview_window()'
  " catch /:E325:/
  "   " User is already prompted about existing swap at the moment. Suppress.
  catch
    call s:close_preview_window()
    echoerr v:exception
  finally
    let preview_buffer.is_new = 0
    call s:goto_window(search_window)
  endtry
endfu

fu! s:save_buffer_variables(preview_buffer) abort
  let a:preview_buffer.guard.winhighlight = nvim_win_get_option(s:preview_window.id, 'winhighlight')
  let a:preview_buffer.guard.swapfile = !!nvim_buf_get_option(a:preview_buffer.id, 'swapfile')
endfu

fu! s:setup_events() abort
  augroup Preview
    au! BufWinEnter,BufEnter <buffer>
    noautocmd au BufWinEnter,BufEnter <buffer> ++once call s:make_preview_buffer_regular()
  augroup END
endfu

fu! s:setup_matched_line_sign(line_in_file) abort
  if empty(sign_getdefined(s:sign_name))
    call sign_define(s:sign_name, {'text': '->'})
  endif

  noautocmd call sign_place(s:sign_id,
        \ s:sign_group,
        \ s:sign_name,
        \ bufnr('%'),
        \ {'lnum': a:line_in_file})
endfu

fu! s:reshape_preview_window(line_in_file, column_in_file) abort
  noautocmd keepjumps resize 11

  " literally what :help scrolloff does, but without dealing with options
  if line('$') - a:line_in_file < 11
    let topline = line('$') - 11
  else
    let topline = a:line_in_file - (11 / 2)
  endif
  noautocmd keepjumps call winrestview({
        \ 'lnum': a:line_in_file,
        \ 'col': a:column_in_file,
        \ 'topline': topline,
        \ })
endfu

fu! s:load_highlight() abort
  noautocmd keepjumps setlocal winhighlight=Normal:NormalFloat
  keepjumps doau BufReadPre
  keepjumps doau BufRead
endfu

fu! s:open_preview_window(preview_buffer) abort

  let id = nvim_open_win(a:preview_buffer, 0, {
        \ 'width':     120,
        \ 'height':    11,
        \ 'focusable': v:false,
        \ 'row':       (getpos('.')[1] - line('w0') + 2),
        \ 'col':       max([5, wincol() - 1]),
        \'relative':   'editor',
        \})
  let number = win_id2win(id)
  return {'id': id, 'number': number}
endfu

fu! s:open_file(filename) abort
  noautocmd keepjumps noswapfile exe 'keepjumps noautocmd noswapfile edit! ' . a:filename
endfu

fu! s:goto_window(window) abort
  noautocmd keepjumps exe a:window . 'wincmd w'
endfu

fu! s:make_preview_buffer_regular() abort
  " execute once
  au! Preview BufWinEnter,BufEnter <buffer>

  let current_filename = expand('%')
  if !has_key(g:preview_buffers_registry, current_filename)
    " another execute once guard
    " shouldn't normally happen because of the command above, but it's
    " acceptable to just suppress.
    return
  endif

  let preview_buffer = g:preview_buffers_registry[current_filename]
  let &l:winhighlight = preview_buffer.guard.winhighlight
  try
    let &l:swapfile = preview_buffer.guard.swapfile
  catch /:E325:/
    " User is already prompted about existing swap at the moment. Suppress.
    " Occurs when preview is opened and :new command is executed
  finally
    call remove(g:preview_buffers_registry, current_filename)
  endtry
endfu

fu! s:initialize_buffer(filename) abort
  if has_key(g:preview_buffers_registry, a:filename)
    return g:preview_buffers_registry[a:filename]
  endif

  let id = nvim_create_buf(1, 0)
  let g:preview_buffers_registry[a:filename] = {
        \ 'id': id,
        \ 'is_new': 1,
        \ 'is_opened': 0,
        \ 'guard': {},
        \ }
  return g:preview_buffers_registry[a:filename]
endfu

fu! s:close_preview_window() abort
  call sign_unplace(s:sign_group, {'id': s:sign_id})

  if exists('s:preview_window') && s:preview_window isnot -1
    exe s:preview_window.number . 'close'
    let s:preview_window = -1
  endif
endfu
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

" let from = line_in_file-5 < 1 ? 1 : line_in_file-4
" let to = line_in_file+5 > len(lines) ? len(lines) : line_in_file+4
" call nvim_buf_set_lines(preview_buffer, 0, -1, 0, map(lines[from:to], '" ".v:val'))
" call nvim_buf_set_lines(preview_buffer, 0, -1, 0, lines)
