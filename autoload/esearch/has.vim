let g:esearch#has#debounce = has('timers')
let g:esearch#has#getqflist_lines = has('patch8.0.1031')
let g:esearch#has#windows = has('win32')

" 7.3.896 memory leaks in Lua interface
let s:fixed_lua = (v:version > 703 || v:version == 703 && has('patch896'))
let g:esearch#has#nvim_lua = has('nvim') && !g:esearch#has#windows && s:fixed_lua
let g:esearch#has#vim_lua = !has('nvim') && has('lua') && !g:esearch#has#windows && s:fixed_lua
unlet s:fixed_lua
let g:esearch#has#lua = g:esearch#has#nvim_lua || g:esearch#has#vim_lua
