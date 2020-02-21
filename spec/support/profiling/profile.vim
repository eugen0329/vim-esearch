profile start profile.log
profile file *
profile func *

if has('nvim')
  command KK profile stop | edit profile.log
else
  command KK qall
endif

call esearch#init()
