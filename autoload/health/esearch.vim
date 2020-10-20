fu! health#esearch#check() abort
  try
    let util = esearch#config#default_adapter()
    if util ==# 'grep' || util ==# 'git'
      call health#report_warn("Can't find a fast search util executable.", "Install one of rg, ag, pt or ack.")
    else
      call health#report_ok('Search util "' . util . '" is available.')
    endif
  catch 
    call health#report_error("Can't find a search util executable.", "Install one of rg, ag, pt or ack.")
  endtry
  if g:esearch#has#lua
    call health#report_ok('Lua interface is available.')
  else
    call health#report_warn("Lua interface isn't available.", "Install vim with lua support for better performance.")
  endif
  if g:esearch#has#jobs
    call health#report_ok('Asynchronous processing is available.')
  else
    call health#report_warn("Asynchronous processing isn't available.", "Install vim with job control.")
  endif

  if g:esearch#has#preview
    call health#report_ok('Floating preview feature is available.')
  else
    call health#report_info("Floating preview feature isn't available. Neovim of version >=0.4.0 is required.")
  endif
  if g:esearch#has#annotations
    call health#report_ok('Virtual text annotations are available.')
  else
    call health#report_info("Virtual text annotations aren't available. Neovim of version >=0.4.3 is required.")
  endif
  if g:esearch#has#unicode
    call health#report_ok('Unicode icons are available.')
  else
    call health#report_info("Unicode icons aren't available. +multi_byte feature and utf-8 encoding settings are required")
  endif
endfu
