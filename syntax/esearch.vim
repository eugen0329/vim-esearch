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

if !highlight_exists('EsearchMatch')
  exe "hi EsearchMatch cterm=bold gui=bold " .
        \ "ctermbg=".synIDattr(synIDtrans(hlID("DiffChange")), "bg", "cterm")." ".
        \ "ctermfg=".synIDattr(synIDtrans(hlID("DiffChange")), "fg", "cterm")." ".
        \ "guibg=" . synIDattr(synIDtrans(hlID("DiffChange")), "bg", "gui")." ".
        \ "guifg=" . synIDattr(synIDtrans(hlID("DiffChange")), "fg", "gui")." "
endif

let b:current_syntax = "esearch"
