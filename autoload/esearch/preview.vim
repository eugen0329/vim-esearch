let s:sign_id = 1

fu! esearch#preview#start() abort
  call sign_define('EsearchPreviewResult', {'text': '->'})

  let filename = esearch#out#win#filename()
  let line_in_file = esearch#out#win#line_in_file()
  let column_in_file = esearch#out#win#column_in_file()

  let preview_buffer = s:initialize_buffer()
  call nvim_buf_set_option(preview_buffer, 'syntax', 'ON')
  let g:__old_swapfile = nvim_buf_get_option(preview_buffer, 'swapfile')

  call s:close_preview_window()

  let search_window = bufwinnr(bufnr('%'))
  try
    let s:preview_winid = s:open_preview_window(preview_buffer)
    let s:preview_window = win_id2win(s:preview_winid)
    let g:__old_winhighlight = nvim_win_get_option(s:preview_winid, 'winhighlight')

    call s:goto_window(s:preview_window)
    call s:open_file(filename)

    noautocmd au BufWinEnter,BufEnter <buffer> ++once call s:restore_buffer_configurations()
    doau BufReadPre
    doau BufRead

    noautocmd keepjumps resize 11
    let dl = line('$') - line_in_file
    call winrestview({
          \ 'lnum': line_in_file,
          \ 'col': column_in_file,
          \ 'topline': dl < 11 ? line('$') - 11 : line_in_file - (11 / 2),
          \ })

    let s:sign_buffer = bufnr('%')
    call sign_place(s:sign_id, 'ESearchPreviewResultSigns','EsearchPreviewResult', s:sign_buffer, {'lnum': line_in_file})

    noautocmd keepjumps setlocal winhighlight=Normal:NormalFloat

    call s:goto_window(search_window)
    au CmdlineEnter,QuitPre,ExitPre,BufWinLeave,WinLeave,BufLeave,CursorMoved * ++once call s:close_preview_window()
  catch
    echoerr v:exception
    call s:close_preview_window()
  finally
  endtry
endfu

fu! s:open_preview_window(preview_buffer) abort
  return nvim_open_win(a:preview_buffer, 0, {
        \ 'width':     120,
        \ 'height':    11,
        \ 'focusable': v:false,
        \ 'row':       (getpos('.')[1] - line('w0') + 2),
        \ 'col':       max([5, wincol() - 1]),
        \'relative':   'editor',
        \})
endfu

fu! s:open_file(filename) abort
  noautocmd keepjumps noswapfile exe 'keepjumps noautocmd noswapfile edit! ' . a:filename
endfu

fu! s:goto_window(window) abort
  noautocmd keepjumps exe a:window . 'wincmd w'
endfu

fu! s:restore_buffer_configurations() abort
  let &l:winhighlight = g:__old_winhighlight
  let &l:swapfile = g:__old_swapfile " throws an error if swap exists, so must be called last
endfu

fu! s:initialize_buffer() abort
  let preview_buffer = nvim_create_buf(1, 0)
  return preview_buffer
endfu

fu! s:close_preview_window() abort
  call sign_unplace('ESearchPreviewResultSigns', {'id': s:sign_id})

  if exists('s:preview_window') && s:preview_window isnot -1
    exe s:preview_window . 'close!'
    let s:preview_window = -1
  endif
endfu

" let from = line_in_file-5 < 1 ? 1 : line_in_file-4
" let to = line_in_file+5 > len(lines) ? len(lines) : line_in_file+4
" call nvim_buf_set_lines(preview_buffer, 0, -1, 0, map(lines[from:to], '" ".v:val'))
" call nvim_buf_set_lines(preview_buffer, 0, -1, 0, lines)
