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

if !highlight_exists('ESearch')
  exe "hi ESearchMatch cterm=bold gui=bold " .
        \ "ctermbg=".esearch#util#highlight_attr("MoreMsg", "bg", "cterm", 239 )." ".
        \ "ctermfg=".esearch#util#highlight_attr("MoreMsg", "fg", "cterm", 15 )." ".
        \ "guibg=" . esearch#util#highlight_attr("MoreMsg", "bg", "gui",   '#005FFF')." ".
        \ "guifg=" . esearch#util#highlight_attr("MoreMsg", "fg", "gui",   '#FFFFFF')." "
endif

let b:current_syntax = "esearch"
