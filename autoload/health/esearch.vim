" health#report_*() were deprecated in Nvim 0.10 and removed in 0.12 (E117 in
" :checkhealth, shown as "E5009: Invalid $VIMRUNTIME"). Use vim.health when
" available and fall back to the legacy functions on older versions.
fu! s:report(level, msg, ...) abort
  if has('nvim-0.10')
    call luaeval('vim.health[_A[1]](_A[2], _A[3])', [a:level, a:msg, get(a:, 1, v:null)])
  else
    call call('health#report_' . a:level, [a:msg] + a:000)
  endif
endfu

fu! health#esearch#check() abort
  try
    let util = esearch#config#default_adapter()
    if util ==# 'grep' || util ==# 'git'
      call s:report('warn', "Can't find a fast search util executable.", "Install one of rg, ag, pt or ack.")
    else
      call s:report('ok', 'Search util "' . util . '" is available.')
    endif
  catch 
    call s:report('error', "Can't find a search util executable.", "Install one of rg, ag, pt or ack.")
  endtry
  if g:esearch#has#lua
    call s:report('ok', 'Lua interface is available.')
  else
    call s:report('warn', "Lua interface isn't available.", "Install vim with lua support for better performance.")
  endif
  if g:esearch#has#jobs
    call s:report('ok', 'Asynchronous processing is available.')
  else
    call s:report('warn', "Asynchronous processing isn't available.", "Install vim with job control.")
  endif

  if g:esearch#has#preview
    call s:report('ok', 'Floating preview feature is available.')
  else
    call s:report('info', "Floating preview feature isn't available. Neovim of version >=0.4.0 is required.")
  endif
  if g:esearch#has#annotations
    call s:report('ok', 'Virtual text annotations are available.')
  else
    call s:report('info', "Virtual text annotations aren't available. Neovim of version >=0.4.3 is required.")
  endif
  if g:esearch#has#unicode
    call s:report('ok', 'Unicode icons are available.')
  else
    call s:report('info', "Unicode icons aren't available. +multi_byte feature and utf-8 encoding settings are required")
  endif
endfu
