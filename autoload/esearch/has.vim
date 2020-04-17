let g:esearch#has#debounce = has('timers')
let g:esearch#has#bufadd = exists('*bufadd')
let g:esearch#has#meta_key = has('nvim') || has('gui_running')
let g:esearch#has#windows = has('win32')
let g:esearch#has#nvim_add_highlight = exists('*nvim_buf_clear_namespace') && exists('*nvim_buf_add_highlight')
let g:esearch#has#virtual_cursor_linenr_highlight = !has('nvim') || g:esearch#has#nvim_add_highlight
let g:esearch#has#nvim_lua_syntax = has('nvim') && exists('*nvim_buf_attach') && g:esearch#has#nvim_add_highlight
let g:esearch#has#unicode = has('multi_byte') && (&termencoding ==# 'utf-8' || &encoding ==# 'utf-8')
let g:esearch#has#preview = has('nvim') && exists('*nvim_open_win')
let g:esearch#has#nvim_jobs = has('nvim') && exists('*jobstart')
let g:esearch#has#nvim_winid = exists('*nvim_set_current_win') && exists('*nvim_get_current_win')
let g:esearch#has#vim8_types = exists('v:true') && exists('v:false') && exists('v:null')
let g:esearch#has#nomodeline = has('patch-7.3.438')
let g:esearch#has#virtual_text = exists('*nvim_buf_set_virtual_text')

" 7.4.1787 - fix of: channel close callback is invoked before other callbacks
let g:esearch#has#vim8_calls_close_cb_last = has('patch-7.4.1787')
" 7.4.1398 - Implemented close-cb
let g:esearch#has#vim8_jobs = has('job') &&
        \ has('patch-7.4.1398') &&
        \ (g:esearch#has#vim8_calls_close_cb_last || exists('*timer_start'))
" Implemented as a function to not preload unneeded code from
" autoload/vimproc.vim
fu! esearch#has#vimproc() abort
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc
endfu
" 7.3.896 memory leaks in Lua interface
let s:fixed_lua = (v:version > 703 || v:version == 703 && has('patch896'))
let g:esearch#has#nvim_lua = has('nvim') && !g:esearch#has#windows && s:fixed_lua
let g:esearch#has#vim_lua = !has('nvim') && has('lua') && !g:esearch#has#windows && s:fixed_lua
unlet s:fixed_lua
let g:esearch#has#lua = g:esearch#has#nvim_lua || g:esearch#has#vim_lua
