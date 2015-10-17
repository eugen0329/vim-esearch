if exists("b:current_syntax")
  finish
endif

syn match  easysearchTitle   "^\%1l.*"
syn match  easysearchFName   "^\%>2l.*"
syn match  easysearchContext "^\%>2l\s\+.*"
syn match  easysearchLnum    "^\%>2l\s\+\d\+"

hi link easysearchTitle Title
hi link easysearchFName Directory
hi link easysearchContext Normal
hi link easysearchLnum LineNr

let b:current_syntax = "esearch"
